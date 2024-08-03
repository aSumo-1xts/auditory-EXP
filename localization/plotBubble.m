% randomSpkr.mによって行われた音源/音像定位実験の結果を
% バブルチャートでプロットするためのスクリプト

% yyyy-MMdd-HHmm-rS.csvの2行目に、
% 対応する実験結果（回答角度）を書き込んでおくこと！

load carbig



% CSVファイル（回答書き込み済）の読み込み
data1 = readmatrix('2024-0723-0038-rS.csv');
data2 = readmatrix('2024-0723-0045-rS.csv');
data3 = readmatrix('2024-0723-0051-rS.csv');
data4 = readmatrix('2024-0723-0107-rS.csv');
data5 = readmatrix('2024-0723-0114-rS.csv');
tData = horzcat(data1, data2, data3, data4, data5)';  % ひとまとめに結合



% 内容の集計
[uniqueXY, ~, idx] = unique(tData(:, 1:2), 'rows');
cnt = histcounts(idx, 'BinMethod', 'integers', 'BinLimits', ...
    [1, size(uniqueXY, 1)]);                        % 同じ回答内容の出現回数を計上
cntData     = horzcat(tData, cnt(idx)');            % データとして3列目に追加
plotData    = unique(cntData, 'stable', 'rows');    % 同じ回答内容を削除
xData = plotData(:, 1); % 1列目：提示角度（横軸）
yData = plotData(:, 2); % 2列目：回答角度（縦軸）
zData = plotData(:, 3); % 3列目：回答回数（バブルの直径）

% 集計後、一応昇順にソートしておく
[xSorted, key] = sort(xData);   % 1列目を昇順に並べ替える
ySorted        = yData(key);    % 2列目を1列目に合わせて並べ替える
zSorted        = zData(key);    % 2列目を1列目に合わせて並べ替える
% バブルチャートはデータをバブルの面積に反映させる
% 面積ではなく直径としてプロットしたいので、変換しておく
zSorted2r      = 2 * sqrt(pi * zSorted);



% 描画
figure;
% バブルが重なった時のために、透過度を上げておく
bubblechart(xSorted, ySorted, zSorted, 'MarkerFaceAlpha', 0.20);
title('音像定位テスト（方位=16, 試行回数=240）');
xlabel('提示角度 [°]');
ylabel('回答角度 [°]');
xlim([-22.5 360]);
ylim([-22.5 360]);
grid on;
pbaspect([1 1 1]);                              % 図全体のアスペクト比を指定
bubblesize([min(zSorted2r) max(zSorted2r)] *1); % バブルの大きさは等倍
bubblelegend('回答回数', 'Location', 'eastoutside');
% 画像ファイルのフォーマット、名前、解像度を指定して保存
print(gcf, '-dpng', '16dir.png', '-r300');