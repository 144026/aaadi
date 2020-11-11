%% sender routine 0.0.3
function ret = hoprcv()
%% initialize
	fprintf('initializing...');
	clearvars -except times;close all;warning off;
	set(0,'defaultfigurecolor','w');
	addpath ..\..\library
	addpath ..\..\library\matlab
	
	ip = '192.168.2.1';
	addpath BPSK\transmitter
	addpath BPSK\receiver
	
	% Transmit and Receive using MATLAB libiio
	% System Object Configuration
	s = iio_sys_obj_matlab; % MATLAB libiio Constructor
	s.ip_address = ip;
	s.dev_name = 'ad9361';
	s.in_ch_no = 2;
	s.out_ch_no = 2;
	s.in_ch_size = length(txdata);
	s.out_ch_size = length(txdata).*8;
	
	s = s.setupImpl();
	
	input = cell(1, s.in_ch_no + length(s.iio_dev_cfg.cfg_ch));
	output = cell(1, s.out_ch_no + length(s.iio_dev_cfg.mon_ch));
	
	% Set the attributes of AD9361
	input{s.getInChannel('RX_LO_FREQ')} = 2e9;
	input{s.getInChannel('RX_SAMPLING_FREQ')} = 40e6;
	input{s.getInChannel('RX_RF_BANDWIDTH')} = 20e6;
	input{s.getInChannel('RX1_GAIN_MODE')} = 'manual';
	input{s.getInChannel('RX1_GAIN')} = 10;
	input{s.getInChannel('TX_LO_FREQ')} = 2e9;
	input{s.getInChannel('TX_SAMPLING_FREQ')} = 40e6;
	input{s.getInChannel('TX_RF_BANDWIDTH')} = 20e6;
	fprintf('finished.\n');

	fprintf('receiving...');
	while 1
		output = readRxData(s);
		rxdata = xxxx;
	   	[crc_res,urmsg]=my_bpsk_rx_func(rxdata);
		if crc_res == 1 && urmsg(1) = hex2dec('ad') && urmsg(2) == hex2dec('13')
			switch urmsg(3)
				case 0
					;
				case 1
					;
				case 2
					TotalDataCount = ubytes2word(urmsg(5:8));
				case 3
					if ct == TotalDataCount
						break;
					end
					buffer = [buffer,urmsg(5:DataCount+4)];
			end
		else
			;
		end

	end
	fprintf('finished.\n');

	% write to file
	fid = fopen('rcv-test.txt');
	fwrite(fid,buffer);
	fclose(fid);

	% release implementation
	rssi1 = output{s.getOutChannel('RX1_RSSI')};
	s.releaseImpl();
end


%% utility functions
function umsg = packdata(Type,DataCount,Data)
	Magic = [uint8(hex2dec('ad')), uint8(hex2dec('13'))];
	Type = uint8(Type);
	DataCount = uint8(Type);
	Data = [uint8(Data), uint8(zeros(1,56))];
	Data = Data(1:56);
	umsg = [Magic,Type,DataCount,Data];
end

function sendumsg(umsg)
	txdata = my_bpsk_tx_func(umsg);
	txdata = round(txdata .* 2^14);
	txdata=repmat(txdata, 8,1);
	input{1} = real(txdata);
    input{2} = imag(txdata);
	writeTxData(s,input);	 
end

function ret = word2ubytes(uword)
	%% little
	uword = uint32(uword);
	ret = [bitand(bitshift(uword,0),255), bitand(bitshift(uword,-8),255), bitand(bitshift(uword,-16),255), bitand(bitshift(uword,-24),255)];
	ret = uint8(ret);
end

function ret = ubytes2word(ubytes)
	ubytes = uint32(ubytes);
	ret = bitshift(ubytes(1),0) + bitshift(ubytes(2),8) + bitshift(ubytes(3),16) + bitshift(ubytes(4),24); 
	ret = uint32(ret);
end
