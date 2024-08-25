% 飯田一博『頭部伝達関数の基礎と3次元音響システムへの応用』
% 10. 頭部伝達関数の信号処理 によせて



% チャープ信号のバイノーラル録音からインパルス応答を取得する関数
function [IR_L, IR_R, Fs] = getIR(wavName)
    [stereo, Fs] = audioread(wavName);  % バイノーラル録音データを読み込む

    % チャープ信号のパラメータを設定（元のチャープ信号の条件を要確認）
    t   = 0:1/Fs:1; % 1秒の時間ベクトル
    f0  = 20;       % 開始周波数
    f1  = 20000;    % 終了周波数
    
    invChirp = fliplr(chirp(t, f0, t(end), f1));    % 逆チャープ信号を生成

    % チャープ信号と逆チャープ音の畳み込みを行う
    IR_L = conv(stereo(:, 1), invChirp, 'same');
    IR_R = conv(stereo(:, 2), invChirp, 'same');
end



% インパルス応答から適切な窓区間を取得する関数
% ここでは正面方向（nB{0, 0}）に対してのみ作用させ、得られた窓区間をその他の方向にも流用する
function [startPoint, endPoint] = setWin(IR)
    [~, maxIdx] = max(abs(IR));         % インパルス応答が振幅の絶対値をとるサンプル番号を取得
    startPoint  = maxIdx-50;            % そこから50サンプル前を始点とする
    sRange  = IR(startPoint+128 : end); % 始点から数えて128サンプル以降のデータを範囲指定
    zeroX   = find(sRange(1:end-1) .* sRange(2:end) < 0, 1, 'first');   % ゼロクロッシング検出
    endPoint    = startPoint + 128 + zeroX - 1;                         % 終点を設定
end



% setWin関数で取得した窓区間を呼び出して適用する関数
% 48kHzでの録音を前提として、512サンプルの窓区間を取得
function window = useWin(IR, startPoint, endPoint)
    if endPoint < length(IR)
        IR(endPoint+1 : end) = 0;
    end
    window = IR(startPoint : startPoint+511);
end



% 両耳インパルス応答からITDを取得する関数
function ITD = getITD(winIR_L, winIR_R, Fs)
    % 波形の時間差が左右方向の知覚の手掛かりとなる事象は約1.6kHz以下の帯域に限られるため、
    % 1.6kHzをカットオフ周波数とするローパスフィルタをかける
    cutFreq = 1600;
    [b, a]  = butter(4, cutFreq/(Fs/2));    % ローパスフィルタを設定
    filt_L  = filtfilt(b, a, winIR_L);      % フィルタをかける
    filt_R  = filtfilt(b, a, winIR_R);      % フィルタをかける

    % 時間分解能を上げるためにサンプリング周波数を8倍にする
    reWinIR_L   = resample(filt_L, 8, 1);
    reWinIR_R   = resample(filt_R, 8, 1);

    % 両耳間相互相関関数（phiFX）を計算し、そのピーク位置をITDとして取得
    [top, lags] = xcorr(reWinIR_L, reWinIR_R);
    bottom      = sqrt(trapz(reWinIR_L.^2 .* reWinIR_R.^2));
    phiFX       = top ./ bottom;
    [~, maxIndex]   = max(phiFX);

    % サンプリング周波数48[kHz]*8=384[kHz]を考慮して、時間分解能を掛けて補正する
    ITD = lags(maxIndex) * 2.6; % [us]
end



% 両耳インパルス応答からILDを取得する関数
% 紹介されているうち、後者の方法を採用
function ILD = getILD(winIR_L, winIR_R)
    % 各周波数成分のパワーを計算
    power_L = abs(fft(winIR_L)).^2;
    power_R = abs(fft(winIR_R)).^2;

    % パワースペクトルをデシベル単位に変換
    dB_L = pow2db(power_L);
    dB_R = pow2db(power_R);

    % 各周波数成分の平均デシベル差を計算してILDとする
    ILD = max(dB_L - dB_R);
end



% =================================================================================================
% ここからmain関数！
% =================================================================================================

% 正面方向のインパルス応答から、適切な窓区間を取得
[stdIR, ~, ~]   = getIR('example_00.wav');
[sP, eP]        = setWin(stdIR);

% 構造体で諸々を管理したい
nB = struct('wavName', [], 'ITD', [], 'ILD', []);

% wavファイル名は適宜変更すること
% 多くの場合、for文を回すことになると思われる
nB.wavName  = 'example_XX.wav';

% インパルス応答を取得して窓区間を適用
[IR_L, IR_R, Fs]    = getIR(nB.wavName);
L = useWin(IR_L, sP, eP);
R = useWin(IR_R, sP, eP);

nB.ITD  = getITD(L, R, Fs); % ITDを取得
nB.ILD  = getILD(L, R);     % ILDを取得

% 結果を表示
disp([round(spkr) round(dirx) round(nB.ITD) round(nB.ILD)]);