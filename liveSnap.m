function cam = liveSnap
%--------------------------------------------------------------
%  ライブプレビュー + 静止画キャプチャ (imwrite 版)
%   ・SPACE  : snapshot → PNG 保存
%   ・Q / ESC: 終了
%--------------------------------------------------------------
cam = webcam("HDMI USB Camera");            % 必要なら名前で指定

%-- プレビューフィギュア --------------------------------------
fig = figure('Name' ,'SPACE=snap,  Q=quit', ...
    'WindowKeyPressFcn',@keyCB, ...
    'Interruptible','on','BusyAction','cancel');

% preview 先となる image オブジェクト
hIm = image(zeros(1080,1920,3,'uint8'));
preview(cam,hIm);                                         % ← ライブ映像

%-- キー入力コールバック ---------------------------------------
    function keyCB(~,evt)
        switch evt.Key
            case 'space'                         % 撮影
                t0   = tic;                      % タイム計測 (任意)
                img  = snapshot(cam);            % フレーム取得
                fname = ['shot_' ...
                    datestr(now,'yyyymmdd_HHMMSSFFF') '.jpeg'];
                imwrite(img,fname);              % ファイル保存
                fprintf('Saved %s  (%.0f ms)\n', ...
                    fname, toc(t0)*1e3);
            case {'q','escape'}                  % 終了
                closePreview(cam);
                clear cam                        % デバイス解放
                delete(fig);
        end
    end
end