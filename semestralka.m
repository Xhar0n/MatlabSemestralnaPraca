%% nadpis terminalovej aplikacie
fprintf('+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+ +-+-+-+ +-+-+-+-+-+ +-+ +-+-+ \n');
fprintf('|M|A|T|L|A|B| |t|e|r|m|i|n|a|l| |a|p|p| |C|O|V|I|D| |-| |1|9| \n');
fprintf('+-+-+-+-+-+-+ +-+-+-+-+-+-+-+-+ +-+-+-+ +-+-+-+-+-+ +-+ +-+-+ \n');

%% import dat zo suboru
M = readtable('OpenData_Slovakia_Covid_DailyStats.csv','PreserveVariableNames',true);

%% import dat z githubu
% M = readtable('https://raw.githubusercontent.com/Institut-Zdravotnych-Analyz/covid19-data/main/DailyStats/OpenData_Slovakia_Covid_DailyStats.csv');

%% pre "AgTests"a "AgPosit" zmena stringu "NA" na double "0"
M.AgTests = str2double(M.AgTests);
M.AgPosit = str2double(M.AgPosit);

%% vypis instrukcii pre uzivatela
fprintf('Voľby: \n')
fprintf('"1" pre pozitívne PCR testy (celé obdobie) \n')
fprintf('"2" pre PCR testy (denne) \n')
fprintf('"3" pre pozitívne PCR testy (denne) \n')
fprintf('"4" pre počet úmrtí (celé obdobie) \n')
fprintf('"5" pre Ag testy (denne) \n')
fprintf('"6" pre pozitívne Ag testy (denne) \n')
fprintf('"7" pre hospitalizovaných \n')
fprintf('"8" pre najlepší / najhorší časový segment \n')
fprintf('"0" pre ukončenie \n')

%% volba grafu, casoveho okna, medianu a casoveho segmentu ktory sa ma zobrazit, ukoncenie programu
while 1
    chosenBar = inputHandler("Voľba: ", 'i');
    if chosenBar >= 1 && chosenBar <= 7
        dates = inputHandler("Zvoľte časové okno [rrrr-mm-dd/rrrr-mm-dd], [v]: ", 's');
        medianInput = inputHandler("Chcete vypísať len median? [a/N]: ", 's');
        showBar(M, chosenBar, dates, medianInput);
    elseif chosenBar == 8
        segmentInput = inputHandler("Zvoľte časový segment [dd]: ", 'i');
        bestWorstTimeSegment(M, segmentInput);
    elseif chosenBar == 0
        fprintf('Ukončovanie...');
        break 
    else
        fprintf('Nesprávny znak, prosím skúste to znova! \n');
        continue
    end
end

%% 
function showBar(M, x, dates, medianInput)
    %% graf vypise vsetky dni + median
    if dates == "v"
        fprintf('Graf zobrazuje všetky zaznamenané dni \n');
        fprintf('Median %.3f \n', median(M{:,x+1}));

        xAxis = M{:,1};
        yAxis = M{:,x+1};
    else
        %% rozdelenie datumov na dva stringy
        dates = split(dates, "/");

        %% najdenie datumov
        try
            dates{1} = find(M.Datum == dates{1});
            dates{2} = find(M.Datum == dates{2});

            dates = checkSwap(dates);
        catch
            fprintf('Nesprávny dátum, prosím skúste to znova! \n');
            return
        end
        fprintf('Graf zobrazuje %.0f deň/dní)\n', dates(2)-dates(1)+1);
        fprintf('Median %.3f \n', median(M{dates(1):dates(2),x+1}));

        %graf
        xAxis = M{dates(1):dates(2),1};
        yAxis = M{dates(1):dates(2),x+1};
    end

    if lower(medianInput) ~= 'a'
        bar(xAxis, yAxis);
        
        %% nastavenie spravneho formatu cisel pre os Y
        ytickformat('%,.0f')
        ax = gca;
        ax.YAxis.Exponent = 0;
    end
end

%% automaticka zmena nespravnej postupnosti datumu, na spravny
function swapped = checkSwap(x)
    if x{1} > x{2}
        swapped = [x{2}, x{1}];
    else
        swapped = [x{1}, x{2}];
    end
end

%% rozdelovanie na string (pismena) a int (cisla), opatrenie pred errormi, vypis pre uzivatela
function output = inputHandler(prompt, datatype)
    if datatype == 's'
        output = input(prompt, 's');
        if isempty(output)
            fprintf("Nesprávny znak, prosím skúste to znova! \n");
            output = "";
        end
    elseif datatype == 'i'
        output = input(prompt);
        if isempty(output)
            fprintf("Nesprávny znak, prosím skúste to znova! \n");
            output = 727; %hocico okrem 0-8
        end
    end
end

%% najlepsi / najhorsi casovy segment, kedy sa pocet potvrdenych PCR testov, hospitalizovanych alebo umrti zvysil / znizil najviac, v zadanom casovom intervale
function bestWorstTimeSegment(M, n)
    columns = ["Pocet.potvrdenych.PCR.testami" "Pocet.hospitalizovanych" "Pocet.umrti"];
    for column = columns
        loser = [0 0 0];
        winner = [0 0 0];
        last = 0;

        %% zacina na n-tom riadku, prechadza kazdy n-ty riadok, porovnava s poslednym, a ulozi ho,
        for i = n:n:length(M{:, 1})
            total = M{i, column};
            if loser(1) < total-last
                loser(1) = total-last;
                loser(2) = i;
                loser(3) = i+n;
            end
            if winner(1) > total-last || (winner(1) == 0 && winner(2) == 0) % (opatrenie pri prvom tyzdni)
                winner(1) = total-last;
                winner(2) = i;
                winner(3) = i+n;
            end
            last = total;
        end
        fprintf("%s v %d dnovych segmentoch: \n", column, n);
        fprintf("\tNajmenej pripadov: %0.f  medzi %s a %s \n", winner(1), M{winner(2), 1}, M{winner(3), 1});
        fprintf("\tNajviac pripadov: %0.f  medzi %s a %s \n", loser(1), M{loser(2), 1}, M{loser(3), 1});
    end
end