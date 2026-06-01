function eigenSpaceCG()
% 固有空間法による姿勢推定: CG学習 vs 実画像学習（Sim2Real）の比較
%
% 改修実験の核「CG画像で学習した固有空間が実機画像の姿勢を当てられるか
% （Sim2Realドメインギャップ）」を実データで評価する。
%
% 評価軸（データを差し替えれば拡張可能）:
%   軸1  : real学習 → realテスト        … 同ドメイン基準
%   軸1' : CG学習   → realテスト        … Sim2Real（ドメインギャップの定量化）
%   軸2/3: 上記を「条件変更した実機テスト」に対して回す（条件変更データ取得後）
%
% 前処理（既定 FULL）:
%   FULL : 画像全体を100x100にimresize（元 mainEigenSpace.mlx と同じ）。
%          実データでは同ドメイン精度が良い（暗角フレームでも安定）ため既定。
%   CROP : 前景(最大連結成分)で正方クロップ→正規化。cross-domainのスケール差は
%          緩和するが、暗角フレームの微小前景を拡大してノイズ化し同ドメインを
%          悪化させるため、スケール study 用オプション（P.crop=true）。
%
% データ: 実機=image_%03d.jpeg（番号×10deg）, CG=img_%04d.png + labels.csv
% 依存: MATLAB base + Statistics Toolbox(pca)。Image Processing Toolbox 不要。
clc;
% スクリプト自身の場所を基準にする（配布先のどこに置いても動く）
baseDir = fileparts(mfilename('fullpath'));
if isempty(baseDir); baseDir = pwd; end
cd(baseDir);

% ---- パラメータ ----
P.W = 100; P.H = 100;     % 正規化後サイズ（固有空間の入力次元 = W*H）
P.k = 8;                  % 固有空間の次元
P.crop = false;           % ★ 既定 FULL。true で前景クロップ正規化
P.work = 256;             % CROP時の作業幅
P.fgRel = 0.12;           % CROP時の前景しきい値（最大輝度比）
P.margin = 0.15;          % CROP時の余白
P.saveMontage = false;    % true で前処理結果のモンタージュを保存（目視確認用）

% ★ データの場所（必要に応じて変更）
%   cgDir : 配布されたCG学習データ（教員が生成・配布。レンダラ mRendering は不要）
%   realDir: 実機画像（基準条件）。各自で取得したデータに差し替える
realDir = fullfile('..','data','20250502','renamed');   % exp/data/...（スクリプトは code/）
cgDir   = fullfile('..','data','cg_train');

% ---- データセット読み込み ----
fprintf('=== データ読み込み（前処理: %s） ===\n', ternary(P.crop,'CROP','FULL'));
realAll = loadReal(realDir, 0:10:360, P);
cgAll   = loadCg(cgDir, P);
fprintf('real: %d枚 (0:10:360), CG: %d枚 (%g:%g:%g)\n', ...
    numel(realAll.angle), numel(cgAll.angle), ...
    cgAll.angle(1), cgAll.angle(2)-cgAll.angle(1), cgAll.angle(end));

% 学習/テスト集合（条件変更データが入ったら realTestCond を足して軸2/3へ）
realTrain = pick(realAll, 0:30:360);   % 粗い学習(13枚, 30deg刻み)
realTest  = realAll;                   % 細かいテスト(37枚, 10deg刻み)
cgTrain   = cgAll;                     % CG学習(36枚, 10deg刻み)

% ---- 軸1: 同ドメイン基準 ----
fprintf('\n=== 軸1: real学習(30deg) → realテスト(10deg)  [同ドメイン基準] ===\n');
A = runEigen(realTrain, realTest, P, false);
report('real->real', A);

% ---- 軸1': Sim2Real ----
fprintf('\n=== 軸1'': CG学習(10deg) → realテスト(10deg)  [Sim2Real] ===\n');
B = runEigen(cgTrain, realTest, P, true);
report('CG->real', B);

% ---- 結果図 ----
f = figure('Visible','off','Position',[0 0 1000 380]);
subplot(1,2,1);
plot(A.testAng, A.err, '-o'); grid on; ylim([-180 180]);
xlabel('true angle [deg]'); ylabel('error [deg]');
title(sprintf('axis1 real->real  (MAE=%.1f deg)', A.mae));
subplot(1,2,2);
plot(B.testAng, B.estAng, 'o'); grid on;
xlabel('true real angle [deg]'); ylabel('estimated (CG-frame) [deg]');
title(sprintf('axis1'' CG->real  (aligned MAE=%.1f deg)', B.alignMae));
print(f, 'eigenSpaceCG_result.png', '-dpng', '-r120');
fprintf('\n結果図 → eigenSpaceCG_result.png\n');

if P.saveMontage
    saveMontage(realTrain, 'dbg_realTrain.png');
    saveMontage(cgTrain,  'dbg_cgTrain.png');
    fprintf('モンタージュ → dbg_realTrain.png, dbg_cgTrain.png\n');
end
end

% ----------------------------------------------------------------------
function S = loadReal(dir, angles, P)
M=P.W*P.H; n=numel(angles); S.data=zeros(M,n); S.angle=angles;
for i=1:n
    f = fullfile(dir, sprintf('image_%03d.jpeg', round(angles(i)/10)));
    S.data(:,i) = preprocess(imread(f), P);
end
end

function S = loadCg(dir, P)
T = readtable(fullfile(dir,'labels.csv'));
M=P.W*P.H; n=height(T); S.data=zeros(M,n); S.angle=T.theta_deg(:)';
for i=1:n
    f = fullfile(dir, sprintf('img_%04d.png', T.frame(i)));
    S.data(:,i) = preprocess(imread(f), P);
end
end

function v = preprocess(img, P)
g = im2double(im2gray(img));
if ~P.crop
    crop = imresize(g, [P.H P.W]);                 % FULL: 全画面リサイズ
else
    sc = P.work / size(g,2);
    gw = imresize(g, [round(size(g,1)*sc) P.work]);
    mask = gw > max(gw(:))*P.fgRel;
    [r0,r1,c0,c1] = largestBlobBBox(mask);
    cy=(r0+r1)/2; cx=(c0+c1)/2;
    side=max(r1-r0,c1-c0)*(1+P.margin); half=side/2; pad=ceil(half)+2;
    gp=zeros(size(gw,1)+2*pad, size(gw,2)+2*pad);
    gp(pad+1:pad+size(gw,1), pad+1:pad+size(gw,2))=gw;
    yy=round(cy+pad-half)+(0:round(side)); xx=round(cx+pad-half)+(0:round(side));
    crop = imresize(gp(yy,xx), [P.H P.W]);
end
v = reshape(crop, [], 1);
end

function [r0,r1,c0,c1] = largestBlobBBox(mask)
% 4近傍連結成分をベクトル化ラベル伝播で求め最大成分のbboxを返す（IPT不要）
[H,W]=size(mask);
if ~any(mask(:)), r0=1;r1=H;c0=1;c1=W; return; end
lbl=reshape(1:H*W,H,W); lbl(~mask)=0;
while true
    cand=cat(3, lbl, shiftz(lbl,-1,1), shiftz(lbl,1,1), shiftz(lbl,-1,2), shiftz(lbl,1,2));
    cand(cand==0)=inf; nl=min(cand,[],3); nl(~mask)=0; nl(isinf(nl))=0;
    if isequal(nl,lbl), break; end
    lbl=nl;
end
ids=lbl(lbl>0); u=unique(ids); cnt=histc(ids,u);
[~,bi]=max(cnt); [ys,xs]=find(lbl==u(bi));
r0=min(ys);r1=max(ys);c0=min(xs);c1=max(xs);
end

function s = shiftz(A,d,dim)
s=circshift(A,d,dim);
if dim==1, if d==-1, s(end,:)=0; else, s(1,:)=0; end
else, if d==-1, s(:,end)=0; else, s(:,1)=0; end, end
end

function R = runEigen(train, test, P, align)
c=mean(train.data,2); coeff=pca(train.data'); E=coeff(:,1:P.k);
g=E'*(train.data-c); nt=numel(test.angle); est=zeros(1,nt);
for i=1:nt
    z=E'*(test.data(:,i)-c); d=vecnorm(z-g,2,1); [~,ix]=min(d);
    if ix==1, ix2=2; elseif ix==numel(d), ix2=numel(d)-1;
    elseif d(ix-1)<d(ix+1), ix2=ix-1; else, ix2=ix+1; end
    w1=d(ix); w2=d(ix2); a1=train.angle(ix); a2=a1+wrap(train.angle(ix2)-a1);
    est(i)=(w2*a1+w1*a2)/(w1+w2);          % 距離の逆比で加重平均
end
R.testAng=test.angle; R.estAng=est; R.err=wrap(test.angle-est);
R.mae=mean(abs(R.err)); R.maxe=max(abs(R.err));
if align
    % CGとrealの姿勢角原点・回転向きは未登録。符号(±1)＋循環オフセットを
    % 最適化した残差で「外形の多様体が転移するか」を評価する。
    best=inf;
    for s=[1 -1]
        resid=wrap(test.angle-s*est);
        off=atan2(mean(sind(resid)),mean(cosd(resid)))*180/pi;
        e=abs(wrap(resid-off));
        if mean(e)<best, best=mean(e); R.alignSign=s; R.alignOff=off; R.alignErr=e; end
    end
    R.alignMae=best; R.alignMax=max(R.alignErr);
end
end

function report(name, R)
fprintf('[%s] 平均絶対誤差 = %.2f deg, 最大 = %.2f deg\n', name, R.mae, R.maxe);
if isfield(R,'alignMae')
    fprintf('   位相アライン後 (sign=%+d, offset=%.1f deg): 平均絶対誤差 = %.2f deg, 最大 = %.2f deg\n', ...
        R.alignSign, R.alignOff, R.alignMae, R.alignMax);
end
end

function saveMontage(S, fname)
n=numel(S.angle); cols=ceil(sqrt(n)); rows=ceil(n/cols);
W=100; H=100; canvas=zeros(rows*H, cols*W);
for i=1:n
    im=reshape(S.data(:,i),[H W]); im=im/max(im(:)+eps);
    r=floor((i-1)/cols); c=mod(i-1,cols);
    canvas(r*H+(1:H), c*W+(1:W))=im;
end
imwrite(canvas, fname);
end

function T = pick(S, angles)
[tf,loc]=ismember(angles,S.angle); loc=loc(tf);
T.data=S.data(:,loc); T.angle=S.angle(loc);
end

function y = wrap(d), y=mod(d+180,360)-180; end
function o = ternary(c,a,b), if c, o=a; else, o=b; end, end
