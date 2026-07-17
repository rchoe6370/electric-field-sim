function electric_field_sim()
    close all force; clear; clc;

    chargeMode = true;
    snapMode = true;
    chargesData = struct('x', {}, 'y', {}, 'strength', {}, 'color', {}, 'pointHandle', {}, 'textHandle', {});
    selectedIndex = -1;
    fontSize = 14;

    RED = [0.9, 0.3, 0.3];
    BLUE = [0.2, 0.5, 0.9];
    DARK = [0.15, 0.15, 0.15];
    GRAY = [0.5, 0.5, 0.5];

    linesPerCharge = 4;

    % Array of per-line graphics handles, one per traced field line.
    fieldLineHandles = gobjects(1, 0);

    % Main window
    f = uifigure('Name', 'Electric Field Simulation', 'Color', 'black');
    f.WindowState = 'maximized';
    drawnow;

    % Root
    root = uigridlayout(f, [1, 2]);
    root.ColumnWidth = {'4x', '1x'};
    root.RowHeight = {'1x'};
    root.Padding = [0, 0, 0, 0];
    root.RowSpacing = 0;
    root.ColumnSpacing = 0;

    % Simulation axes
    simGrid = uigridlayout(root, [1, 1]);
    simGrid.Layout.Row = 1;
    simGrid.Layout.Column = 1;
    simGrid.Padding = [0, 0, 0, 0];
    simGrid.BackgroundColor = 'black';
    simGrid.RowSpacing = 0;
    simGrid.ColumnSpacing = 0;

    ax = uiaxes(simGrid);
    ax.Layout.Row = 1;
    ax.Layout.Column = 1;
    ax.Color = 'black';
    ax.XColor = 'none';
    ax.YColor = 'none';
    ax.XTick = 0:0.05:1;
    ax.YTick = 0:0.05:1;
    ax.XTickLabel = [];
    ax.YTickLabel = [];
    ax.GridColor = [0.5, 0.5, 0.5];
    ax.GridAlpha = 0.6;
    ax.DataAspectRatio = [1, 1, 1];
    xlim(ax, [0, 1]);
    ylim(ax, [0, 1]);
    grid(ax, 'on');
    hold(ax, 'on');

    % Mouse events
    ax.ButtonDownFcn = @(~, ~) canvasClick();

    % Control panel
    cp = uipanel(root);
    cp.BackgroundColor = DARK;
    cp.ForegroundColor = 'white';
    cp.Title = 'Controls';
    cp.Layout.Row = 1;
    cp.Layout.Column = 2;

    ctrlGrid = uigridlayout(cp, [10, 1]);
    ctrlGrid.RowHeight = {40, 40, 40, 40, 40, 40, 40, 40, '1x','1x'};
    ctrlGrid.ColumnWidth = {'1x'};
    ctrlGrid.Padding = [10, 10, 10, 10];
    ctrlGrid.RowSpacing = 8;
    ctrlGrid.BackgroundColor = DARK;

    % UI elements
    chargeBtn = uibutton(ctrlGrid, 'state', 'Text', 'Charge Mode');
    chargeBtn.Layout.Row = 1;
    chargeBtn.Value = true;
    chargeBtn.FontSize = fontSize;
    chargeBtn.FontColor = 'white';
    chargeBtn.ValueChangedFcn = @(~, ~) changeChargeMode();

    snapBtn = uibutton(ctrlGrid, 'state', 'Text', 'Snap to Grid');
    snapBtn.Layout.Row = 2;
    snapBtn.Value = true;
    snapBtn.FontSize = fontSize;
    snapBtn.FontColor = 'white';
    snapBtn.ValueChangedFcn = @(~, ~) changeSnapMode();

    single = uibutton(ctrlGrid, 'Text', 'Single');
    single.Layout.Row = 3;
    single.FontSize = fontSize;
    single.FontColor = 'white';
    single.ButtonPushedFcn = @(~, ~) spawnSingle();

    dipole = uibutton(ctrlGrid, 'Text', 'Double');
    dipole.Layout.Row = 4;
    dipole.FontSize = fontSize;
    dipole.FontColor = 'white';
    dipole.ButtonPushedFcn = @(~, ~) spawnDipole();

    row = uibutton(ctrlGrid, 'Text', 'Row');
    row.Layout.Row = 5;
    row.FontSize = fontSize;
    row.FontColor = 'white';
    row.ButtonPushedFcn = @(~, ~) spawnRow();

    random = uibutton(ctrlGrid, 'Text', 'Random');
    random.Layout.Row = 6;
    random.FontSize = fontSize;
    random.FontColor = 'white';
    random.ButtonPushedFcn = @(~, ~) spawnRandom();

    chargeSlider = uislider(ctrlGrid);
    chargeSlider.Layout.Row = 7;
    chargeSlider.Limits = [-4, 4];
    chargeSlider.Value = 0;
    chargeSlider.Step = 1;
    chargeSlider.MajorTicks = -4:1:4;
    chargeSlider.MinorTicks = [];
    chargeSlider.ValueChangingFcn = @(~, event) changeSlider(event.Value);

    clearBtn = uibutton(ctrlGrid, 'Text', 'Clear All');
    clearBtn.Layout.Row = 8;
    clearBtn.BackgroundColor = [0.4, 0.4, 0.4];
    clearBtn.FontSize = fontSize;
    clearBtn.FontColor = 'white';
    clearBtn.ButtonPushedFcn = @(~, ~) clearAll();

    % Functions
    function changeChargeMode()
        chargeMode = chargeBtn.Value;
    end

    function changeSnapMode()
        snapMode = snapBtn.Value;
    end

    function canvasClick()
        if chargeMode == true
            x = ax.CurrentPoint(1, 1);
            y = ax.CurrentPoint(1, 2);

            if snapMode == true
                x = round(x / 0.05) * 0.05;
                y = round(y / 0.05) * 0.05;
            end

            hitRadius = 0.03;
            hitIndex = -1;

            for i = 1:length(chargesData)
                dx = chargesData(i).x - x;
                dy = chargesData(i).y - y;
                d = sqrt(dx^2 + dy^2);

                if d <= hitRadius
                    hitIndex = i;
                    break;
                end
            end

            if hitIndex > -1
                selectDot(hitIndex);
                return;
            end

            newCharge.x = x;
            newCharge.y = y;
            newCharge.strength = 0;
            newCharge.color = GRAY;
            newCharge.pointHandle = [];
            newCharge.textHandle = [];

            chargesData(end + 1) = newCharge;
            selectedIndex = length(chargesData);
            chargeSlider.Value = 0;
            redraw();

        end
    end

    function changeSlider(value)
        if selectedIndex > -1
            chargesData(selectedIndex).strength = value;

            if value > 0
                chargesData(selectedIndex).color = RED;
            elseif value < 0
                chargesData(selectedIndex).color = BLUE;
            else
                chargesData(selectedIndex).color = GRAY;
            end

            redraw();

        end
    end

    function spawnSingle()
        clearAll()
        newCharge.x = 0.5;
        newCharge.y = 0.5;
        newCharge.strength = 2;
        newCharge.color = RED;
        newCharge.pointHandle = [];
        newCharge.textHandle = [];

        chargesData(end + 1) = newCharge;
        selectedIndex = length(chargesData);
        chargeSlider.Value = 2;
        redraw()
    end

    function spawnDipole()
        clearAll()
        newCharge.x = 0.3;
        newCharge.y = 0.5;
        newCharge.strength = -2;
        newCharge.color = BLUE;
        newCharge.pointHandle = [];
        newCharge.textHandle = [];

        chargesData(end + 1) = newCharge;
        selectedIndex = length(chargesData);
        chargeSlider.Value = -2;

        newCharge.x = 0.7;
        newCharge.y = 0.5;
        newCharge.strength = 2;
        newCharge.color = RED;
        newCharge.pointHandle = [];
        newCharge.textHandle = [];

        chargesData(end + 1) = newCharge;
        selectedIndex = length(chargesData);
        chargeSlider.Value = 2;
        redraw()

    end

    function spawnRow()
        clearAll()

        x = 0.4
        y = 0.5
        num = 3

        for i = 1:num
            newCharge.x = x;
            newCharge.y = y;
            newCharge.strength = -2;
            newCharge.color = BLUE;
            newCharge.pointHandle = [];
            newCharge.textHandle = [];
    
            chargesData(end + 1) = newCharge;
            selectedIndex = length(chargesData);
            chargeSlider.Value = -2;

            x = x + 0.1
        end


        
        redraw()
    end

    function spawnRandom()
        clearAll();

        num = 3;

        for i = 1:num
            x = randi([0, 20]) * 0.05;
            y = randi([0, 20]) * 0.05;

            ints = [-4:-1, 1:4];


            charge = ints(randi([1, 8]));

            newCharge.x = x;
            newCharge.y = y;
            newCharge.strength = charge;

            if charge < 0
                newCharge.color = BLUE;
            else 
                newCharge.color = RED;
            end

            newCharge.pointHandle = [];
            newCharge.textHandle = [];
    
            chargesData(end + 1) = newCharge;
            selectedIndex = length(chargesData);
            chargeSlider.Value = charge;


        end

        redraw();

    end

    function clearAll()
        chargesData = struct('x', {}, 'y', {}, 'strength', {}, 'color', {}, 'pointHandle', {}, 'textHandle', {});
        selectedIndex = -1;
        cla(ax);
        grid(ax, 'on');
        hold(ax, 'on');
        fieldLineHandles = gobjects(1, 0);
    end

    % Returns the net field vector at a point
    function [ex, ey] = fieldAt(x, y, allX, allY, allQ)
        dx = x - allX;
        dy = y - allY;
        r2 = dx.^2 + dy.^2;
        r2(r2 < 1e-6) = 1e-6;
        ex = sum(allQ .* dx ./ r2);
        ey = sum(allQ .* dy ./ r2);
    end

    function t = segmentCircleHit(x1, y1, x2, y2, cx, cy, r)
        dx = x2 - x1;
        dy = y2 - y1;
        fx = x1 - cx;
        fy = y1 - cy;

        a = dx^2 + dy^2;
        c = fx^2 + fy^2 - r^2;

        if c <= 0
            t = 0; % Already inside the circle at the start of this step
            return;
        end

        if a < 1e-12
            t = NaN;
            return;
        end

        b = 2 * (fx * dx + fy * dy);
        disc = b^2 - 4 * a * c;

        if disc < 0
            t = NaN;
            return;
        end

        sqrtDisc = sqrt(disc);
        t1 = (-b - sqrtDisc) / (2 * a);

        if t1 >= 0 && t1 <= 1
            t = t1;
        else
            t = NaN;
        end
    end

    function [px, py, hitIndex] = traceOneLine(x0, y0, allX, allY, allQ, selfIndex, ds, maxSteps, killRadius, traceSign)
        x = x0;
        y = y0;
        px = x;
        py = y;
        hitIndex = 0;

        for step = 1:maxSteps
            [ex, ey] = fieldAt(x, y, allX, allY, allQ);
            mag = sqrt(ex^2 + ey^2);

            if mag < 1e-9
                break;
            end

            nx = x + traceSign * (ex / mag) * ds;
            ny = y + traceSign * (ey / mag) * ds;

            bestT = Inf;
            bestJ = 0;

            for j = 1:numel(allX)
                if j == selfIndex || allQ(j) == 0
                    continue;
                end

                if traceSign == 1 && allQ(j) >= 0
                    continue;
                end

                if traceSign == -1 && allQ(j) <= 0
                    continue;
                end

                t = segmentCircleHit(x, y, nx, ny, allX(j), allY(j), killRadius);
                if ~isnan(t) && t < bestT
                    bestT = t;
                    bestJ = j;
                end
            end

            if bestJ > 0
                x = x + bestT * (nx - x);
                y = y + bestT * (ny - y);
                px(end + 1) = x;
                py(end + 1) = y;
                hitIndex = bestJ;
                break;
            end

            x = nx;
            y = ny;
            px(end + 1) = x;
            py(end + 1) = y;

            if x < 0 || x > 1 || y < 0 || y > 1
                break;
            end
        end
    end

    function paths = computeFieldLinePaths(ds, maxSteps)
    
        allX = [chargesData.x];
        allY = [chargesData.y];
        allQ = [chargesData.strength];
    
        paths = struct('x', {}, 'y', {});
    
        if isempty(allQ) || all(allQ == 0)
            return;
        end
    
        killRadius = 0.015;
        seedRadius = 0.015;
        numCharges = numel(allQ);
    
        endpoints = zeros(1, numCharges);
        for i = 1:numCharges
            if allQ(i) == 0
                continue;
            end
            endpoints(i) = max(1, round(linesPerCharge * abs(allQ(i))));
        end
    
        arrivalAngles = cell(1, numCharges);
        for i = 1:numCharges
            arrivalAngles{i} = [];
        end
    
        % Pass 1: every positive charge emits its full quota
        for i = 1:numCharges
            if allQ(i) <= 0
                continue;
            end
    
            for k = 0:endpoints(i) - 1
                theta = 2 * pi * k / endpoints(i);
                x0 = allX(i) + seedRadius * cos(theta);
                y0 = allY(i) + seedRadius * sin(theta);
    
                [px, py, hitIndex] = traceOneLine(x0, y0, allX, allY, allQ, i, ds, maxSteps, killRadius, 1);
    
                if hitIndex > 0 && allQ(hitIndex) < 0 && numel(px) >= 2
                    arrivalAngle = atan2(py(end) - allY(hitIndex), px(end) - allX(hitIndex));
                    arrivalAngles{hitIndex}(end + 1) = arrivalAngle;
                end
    
                % Always drawn. This line is real no matter where it lands.
                paths(end + 1).x = px;
                paths(end).y = py;
            end
        end
    
        % Pass 2: top up any negative charge that's short of quota
        for i = 1:numCharges
            if allQ(i) >= 0
                continue;
            end
    
            shortfall = endpoints(i) - numel(arrivalAngles{i});
            if shortfall <= 0
                continue;
            end
    
            idealStep = 2 * pi / endpoints(i);
            gapTolerance = idealStep * 0.5;
    
            added = 0;
            for k = 0:endpoints(i) - 1
                if added >= shortfall
                    break;
                end
    
                theta = 2 * pi * k / endpoints(i);
    
                if ~isempty(arrivalAngles{i})
                    diffs = abs(mod(arrivalAngles{i} - theta + pi, 2 * pi) - pi);
                    if any(diffs < gapTolerance)
                        continue;
                    end
                end
    
                x0 = allX(i) + seedRadius * cos(theta);
                y0 = allY(i) + seedRadius * sin(theta);
    
                [px, py, ~] = traceOneLine(x0, y0, allX, allY, allQ, i, ds, maxSteps, killRadius, -1);
    
                paths(end + 1).x = px;
                paths(end).y = py;
                added = added + 1;
            end
        end
    end

    function drawFieldLines(ds, maxSteps)
        % Traces the current set of field lines and draws each one as
        % its own line object.
        for h = fieldLineHandles
            if isvalid(h)
                delete(h);
            end
        end

        paths = computeFieldLinePaths(ds, maxSteps);
        n = numel(paths);
        fieldLineHandles = gobjects(1, n);

        if n == 0
            return;
        end

        for idx = 1:n
            fieldLineHandles(idx) = plot(ax, paths(idx).x, paths(idx).y, ...
                'Color', [1, 1, 1, 0.45], 'LineWidth', 1);
        end

        uistack(fieldLineHandles, 'bottom');
    end

    function redraw()
        cla(ax);
        grid(ax, 'on');
        hold(ax, 'on');

        ds = 0.003;
        maxSteps = 3000;


        drawFieldLines(ds, maxSteps); % Structure changed (charge added/removed/strength changed)

        for i = 1:length(chargesData)
            c = chargesData(i);

            t = drawpoint(ax, 'Position', [c.x, c.y], ...
                'MarkerSize', 20 + abs(c.strength) * 5, ...
                'Color', c.color, ...
                'LabelVisible', 'off');

            t.Selected = (selectedIndex == i);

            t.UserData = i;

            addlistener(t, 'ROIClicked', @(src, ~) onChargeClick(src));

            addlistener(t, 'MovingROI', @chargeMoving);
            addlistener(t, 'ROIMoved', @chargeMoved);

            txt = text(ax, c.x, c.y, num2str(c.strength), ...
                'HorizontalAlignment', 'center', ...
                'VerticalAlignment', 'middle', ...
                'Color', 'White', ...
                'FontWeight', 'bold', ...
                'FontSize', fontSize, ...
                'HitTest', 'off');

            chargesData(i).pointHandle = t;
            chargesData(i).textHandle = txt;
        end
    end

    function onChargeClick(src)
        selectDot(src.UserData);
    end

    function selectDot(index)
        if selectedIndex > 0 && selectedIndex <= numel(chargesData) ...
                && ~isempty(chargesData(selectedIndex).pointHandle) ...
                && isvalid(chargesData(selectedIndex).pointHandle)
            chargesData(selectedIndex).pointHandle.Selected = false;
        end

        selectedIndex = index;
        chargesData(index).pointHandle.Selected = true;
        chargeSlider.Value = chargesData(index).strength;
    end

    function chargeMoving(src, event)
        i = src.UserData;

        if i >= 1 && i <= numel(chargesData)
            pos = event.CurrentPosition;
            chargesData(i).x = pos(1);
            chargesData(i).y = pos(2);

            if ~isempty(chargesData(i).textHandle)
                set(chargesData(i).textHandle, 'Position', [pos(1), pos(2), 0]);
            end

            drawFieldLines(0.01, 150);
            drawnow;
        end
    end

    function chargeMoved(src, event)
        i = src.UserData;

        if i < 1 || i > numel(chargesData)
            return;
        end

        pos = event.CurrentPosition;

        if snapMode
            pos = round(pos / 0.05) * 0.05;
            src.Position = pos;
        end

        chargesData(i).x = pos(1);
        chargesData(i).y = pos(2);

        if ~isempty(chargesData(i).textHandle)
            set(chargesData(i).textHandle, 'Position', [pos(1), pos(2), 0]);
        end

        drawFieldLines(0.003, 600);
    end

end
