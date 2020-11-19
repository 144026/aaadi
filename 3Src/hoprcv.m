%% receiver routine 0.4.0
function ret = hoprcv()
%% initialize
	fprintf('initializing...');
	close all;warning off;
	set(0,'defaultfigurecolor','w');
	addpath ..\..\library
	addpath ..\..\library\matlab
	
	ip = '192.168.2.1';
	addpath BPSK\transmitter
	addpath BPSK\receiver
	
	% Transmit and Receive using MATLAB libiio
	% System Object Configuration
	global s = iio_sys_obj_matlab; % MATLAB libiio Constructor
	s.ip_address = ip;
	s.dev_name = 'ad9361';
	s.in_ch_no = 2;
	s.out_ch_no = 2;
	s.in_ch_size = 42568;
	s.out_ch_size = 42568.*8;
	
	s = s.setupImpl();
	
	global input = cell(1, s.in_ch_no + length(s.iio_dev_cfg.cfg_ch));
	global output = cell(1, s.out_ch_no + length(s.iio_dev_cfg.mon_ch));
	
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
	ct = uint32(0);
	DataCount = uint32(0);
	TotalDataCount = uint32(0);
	bf = uint8([97,97,97,10]);
    aaa=0

	while 1
        aaa=aaa+1;
        aaa
		output = readRxData(s);
		I=output{1};
		Q=output{2};
		rxdata=I+1i*Q;
	   	[crc_res,rUmsg]=my_bpsk_rx_func(rxdata);
		if crc_res == 1 && rUmsg(1) == hex2dec('ad') && rUmsg(2) == hex2dec('13')
			switch rUmsg(3)
				case 0 %Hopping SYN
					;
				case 1 %Hopping ACK
					;
				case 2 %File
					TotalDataCount = ubytes2word(rUmsg(5:8));
				case 3 %File Secondary
                    if TotalDataCount == 0
                        continue;
                    end
                    
					if ct == TotalDataCount
						break;
					end
					DataCount = uint32(rUmsg(4));
					bf = [bf,rUmsg(5:DataCount+4)];
					ct = ct + DataCount;
			end
		else
			;
		end

	end
	fprintf('finished.\n');

	% write to file
	fid = fopen('rcv-test.txt','wb');
	fwrite(fid,bf);
	fclose(fid);

	% release implementation
	rssi1 = output{s.getOutChannel('RX1_RSSI')};
	s.releaseImpl();
	clearvars -except times; 
end


%% functions

%% APIs
function play()
	global s;
	global input;
	global output;

	seq=uint32(0);
	while true
		output = readRxData(s);
		I=output{1};
		Q=output{2};
		rxdata=I+1i*Q;
	   	[crc_res,rUmsg]=my_bpsk_rx_func(rxdata);
		if crc_res==1 && rUmsg(5:8) == seq+1
			seq = seq + 1;
			rcvDispatcher(rUmsg);
		else
			sUmsg=PackUmsg(rUmsg(3),rUmsg(4),seq,rUmsg(9:60));
		end
	end
end

function rcvDispatcher(umsg)
	%% Type definition
	HOPPING_SYN = uint8(0);
	HOPPING_ACK = uint8(1);
	FILE = uint8(2);
	FILE_SECONDARY = uint8(3);

	%% dispatch
	switch umsg(3)
		case HOPPING_SYN 
			CompleteHoppingSYN(umsg);
		case HOPPING_ACK 
			;
		case FILE
			CompleteFile(umsg);
		case FILE_SECONDARY
			CompleteFIleSecondary(umsg);
	end
end

function CompleteFile(umsg)
	main.TotalDataCount = ubytes2word(rUmsg(5:8));
	sendACK
end

function CompleteFileSecondary(umsg)


function umsg = PackUmsg(Type,DataCount,Seq,Data)
	Magic = [uint8(hex2dec('ad')), uint8(hex2dec('13'))];
	Type = uint8(Type);
	DataCount = uint8(DataCount);
	Seq=word2ubytes(uint32(Seq));
	Data = [uint8(Data), uint8(zeros(1,52))];
	Data = Data(1:52);
	umsg = [Magic,Type,DataCount,Seq,Data];
end

function sendumsg(s,input,umsg)
	txdata = my_bpsk_tx_func(umsg);
	txdata = round(txdata .* 2^14);
	txdata=repmat(txdata, 8,1);
	input{1} = real(txdata);
    input{2} = imag(txdata);
	writeTxData(s,input);	 
end
function SendUmsg(umsg)
	global s;
	global input;
	txdata = my_bpsk_tx_func(umsg);
	txdata = round(txdata .* 2^14);
	txdata=repmat(txdata, 8,1);
	input{1} = real(txdata);
    input{2} = imag(txdata);
	writeTxData(s,input);	 
end


%% utilities
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
