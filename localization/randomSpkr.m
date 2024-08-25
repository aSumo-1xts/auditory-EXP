% 最も基本的な音源/音像定位実験のためのスクリプト。
% selectOneCh.slxをスクリプト実行すると、
% howManyCh個のスピーカのうち無作為に選ばれた一つから音源が再生される。
% 履歴はyyyy-MMdd-HHmm-rS.csvに出力されるので、
% 回答結果をそこに書き足し、plotBubble.mでプロットする。



clear; clc; close all;

% ↓ setting var ↓
howManyCh   = 4;    % 総チャンネル数
repeat      = 1;    % 繰り返し数
delayTime   = 1;    % 再生間インターバル[秒]
% ↑ setting var ↑

pause('on');    % ポーズ機能ON



% ファイル名（yyyy-MMdd-HHmm.csv）の生成
date        = datetime('now');
date.Format = 'yyyy-MMdd-HHmm''-rS.csv';
fileName    = char(date);
% 上のCSVファイルに書き込むためのガワを宣言
chDirx = cell(1, howManyCh*repeat);



% Simulinkモデルを読み込み
model = 'selectOneCh';
load_system(model);
% Simulink内の各パラメータへパスを通す
path01 = [model, '/Zero Matrix'];
path02 = [model, '/Select a Channel'];
str01  = append("zeros(sample, ", num2str(howManyCh), ")");



set_param(path01, 'Value', str01);
for i = 1:repeat                            % 総試行回数は howManyCh*repeat回
    speakerNum  = randperm(howManyCh);      % 乱数生成
    for j = 1:howManyCh
        no = (i-1)*howManyCh+j;
        chDirx{no} = rem(speakerNum(1, j), howManyCh) * (360/howManyCh);

	    set_param(path02, 'ColStartIndex', num2str(speakerNum(1, j)));
	    simOut = sim(model, 'ReturnWorkspaceOutputs', 'on');
        pause(delayTime);
    end
end



close_system(model, 0);
writecell(chDirx, fileName);