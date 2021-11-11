function p = GetParamsFromPaths(filePath)
    [~, ~, ext] = fileparts(filePath);
    
    switch ext
        case '.csv'
            T = readcell(filePath);
            Nepochs = width(T)-1;
            Nparams = height(T);
            for jj=1:Nepochs
                for ii=1:Nparams
                    p(jj).(T{ii, 1}) = T{ii, 1+jj};
                end
            end
    end
end