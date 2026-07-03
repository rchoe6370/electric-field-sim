%presets of single, dipole, row, dipole row, random, remove allcharges
%test charge mode, place down test charges
% 

function electric_field_sim()
    close all force; clear; clc;
    
    chargeMode = true;
    snapMode = true;
    chargesData = struct('x', {}, 'y', {}, 'strength', {}, 'color', {}, 'pointHandle', {}, 'textHandle', {});
    selectedIndex = -1;
    fontSize = 14;

    RED  = [0.9, 0.3, 0.3];
    BLUE = [0.2, 0.5, 0.9];
    DARK = [0.15, 0.15, 0.15];
    GRAY = [0.5, 0.5, 0.5];
    
    % Main window
    f = uifigure('Name', 'Electric Field Simulation', 'Color', 'black');
    f.WindowState = 'maximized';
    
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
    ctrlGrid.RowHeight = {40, 40, 40, 40, '1x','1x','1x','1x','1x','1x'};
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

    chargeSlider = uislider(ctrlGrid);
    chargeSlider.Layout.Row = 3;
    chargeSlider.Limits = [-4, 4];
    chargeSlider.Value = 0;
    chargeSlider.Step = 1;
    chargeSlider.MajorTicks = -4:1:4;
    chargeSlider.MinorTicks = [];
    chargeSlider.ValueChangingFcn = @(~, event) changeSlider(event.Value);
    
    clearBtn = uibutton(ctrlGrid, 'Text', 'Clear All');
    clearBtn.Layout.Row = 4;
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

    function clearAll()
        chargesData = struct('x', {}, 'y', {}, 'strength', {}, 'color', {}, 'pointHandle', {}, 'textHandle', {});
        selectedIndex = -1;
        cla(ax);
        grid(ax, 'on');
        hold(ax, 'on');
    end

    function redraw()
        cla(ax);
        grid(ax, 'on');
        hold(ax, 'on');

        for i = 1:length(chargesData)
            c = chargesData(i);
            
            t = drawpoint(ax, 'Position', [c.x, c.y], ... 
                'MarkerSize', 20 + abs(c.strength) * 5, ...
                'Color', c.color, ...
                'LabelVisible', 'off');
                                                    
            t.Selected = (selectedIndex == i);

            t.UserData = i;

            addlistener(t, 'ROIClicked', @(src, ~) selectDot(src.UserData));

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
        
        if i >= 1 && i <= numel(chargesData) && ~isempty(chargesData(i).textHandle)
            pos = event.CurrentPosition;
            
            set(chargesData(i).textHandle, 'Position', [pos(1), pos(2), 0]);
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
              
        set(chargesData(i).textHandle, 'Position', [pos(1), pos(2), 0]);
    
    end





end