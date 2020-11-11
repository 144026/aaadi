function msg_bits = ustr_to_bits(umsg)

msgBin = de2bi(umsg,8,'left-msb');
len = size(msgBin,1).*size(msgBin,2);
msg_bits = reshape(double(msgBin).',len,1).';

end

