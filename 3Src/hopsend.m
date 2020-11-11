%% sender routine
function ret = hopsend(filename)
	fid = fopen(filename);
	bytes = uint8(fread(fid));
	fclose(fid);

	TotalDataCount = length(bytes);
	off = 1;
	if(TotalDataCount > 116)
		DataCount = 116;
	else
		DataCount = TotalDataCount;
	end

	umsg = packdata(2,DataCount,bytes(off:off + DataCount - 1));
	txdata = my_bpsk_tx_func(umsg);
end

%% utility functions
function umsg = packdata(Type,DataCount,Data)
	Magic = [uint8(hex2dec('ad')), uint8(hex2dec('13'))];
	Type = uint8(Type);
	DataCount = uint8(Type);
	Data = [uint8(Data), uint8(zeros(1,116))];
	Data = Data(1:116);
	umsg = [Magic,Type,DataCount,Data];
end
