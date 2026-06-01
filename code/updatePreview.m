function updatePreview(app)
    try
        if ~isempty(app.Camera) && isvalid(app.Camera)
            % フレームを取得
            frame = snapshot(app.Camera);
            
            % タブのAxesに表示
            imshow(frame, 'Parent', app.UIAxes);
            
            % 軸の設定を維持
            app.UIAxes.Visible = 'on';
        end
    catch
        % エラーが発生した場合はタイマーを停止
        if ~isempty(app.PreviewTimer) && isvalid(app.PreviewTimer)
            stop(app.PreviewTimer);
        end
    end
end