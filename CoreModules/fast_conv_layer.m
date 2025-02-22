function [ y, dzdw,dzdb,opts ] = fast_conv_layer( I,kernel,bias,stride,pad,dzdy,opts )
%FAST_CONV Summary of this function goes here
%   Detailed explanation goes here
%calculate three ffts and iffts



[i1,i2,in,b]=size(I);    
    
if(~isempty(pad))
    original_size_r=i1;
    original_size_c=i2;
    i1=i1+pad(1)+pad(2);
    i2=i2+pad(3)+pad(4);
end

[k1,k2,in,out]=size(kernel);    
dzdw=[];  
dzdb=[];  
if isempty(dzdy)
    %forward mode, compute the 'valid' convolution using fft
    if(~isempty(pad))
       I = pad_data(I,pad,[]);       
    end
    
    tk=zeros(i1,i2,in,out,'like',I);
    tk(1:k1,1:k2,:,:)=kernel;      
    kernel=tk;
    
    opts.layer{opts.current_layer}.fI=fft2(I); %store result
    opts.layer{opts.current_layer}.fk=fft2(kernel); %store result
    
   
    y=zeros(i1,i2,out,b,'like',I);
    
    for o=1:out
        fft_conv=bsxfun(@times,opts.layer{opts.current_layer}.fI,opts.layer{opts.current_layer}.fk(:,:,:,o));
        fft_conv=sum(fft_conv,3);
        y(:,:,o,:)=real(ifft2(fft_conv));     
    end
    
    y = y(k1:end,k2:end,:,:);
    if ~isempty(bias)
        bias_p=permute(bias,[4,3,2,1]);%%check this
        y=bsxfun(@plus,y,bias_p);
    end
    
    
    %%%%strided convolution
    if(max(stride)>1)
        y=y(1:stride(1):end,1:stride(2):end,:,:);
    end
    
    
    if opts.training~=1
        opts.layer{opts.current_layer}.fI=[];
        opts.layer{opts.current_layer}.fk=[];
    end
        
else
    %%back prop: load the precomputed ffts and proceed with the
    %%computation.
   
    %%calculate the 'valid' correlation+flipping    
 
    
    
    
    [d1,d2,out,b]=size(dzdy);
    
    td=zeros(i1,i2,out,b,'like',dzdy);
    
    td(1:stride(1):d1,1:stride(2):d2,:,:)=dzdy;
    dzdy=td;
    clear td;
    fdzdy=fft2(dzdy);
    dzdw=zeros(k1,k2,in,out,'like',I);
    
    %%insert the preconditioner here
    
    %%preconditioner end
    
    
    
    for o=1:out
        
        fft_corr=bsxfun(@times,opts.layer{opts.current_layer}.fI,conj(fdzdy(:,:,o,:)));
        fft_corr=mean(fft_corr,4); %minibatch averaging
        fft_corr=real(ifft2(fft_corr));
        dzdw(:,:,:,o)= fft_corr(1:k1,1:k2,:,:);% requires thorough understanding of fft, and the shifts 
    end    
    dzdw=flip(flip(dzdw,1),2);
    
    if ~isempty(bias)
        dzdb=sum(sum(mean(dzdy,4),1),2);   
        %minibatch averaging + patch summing (note this is how much it changes the final loss)
        dzdb=permute(dzdb,[4,3,2,1]);
    end
    
    %%calculate the 'full' correlation   
    y=zeros(i1,i2,in,b,'like',dzdy);%y=dzdx
    fk=permute(opts.layer{opts.current_layer}.fk,[1,2,4,3]);
    
    for i=1:in        
        fft_corr=bsxfun(@times,fdzdy,conj(fk(:,:,:,i)));
        fft_corr=sum(fft_corr,3);
        y(:,:,i,:)=real(ifft2(fft_corr));
    end
    
    %next line is a dirty circular shift, according to matlab fft implementation.
    y=circshift(y,[(k1-1),(k2-1)]); %another crazy shift

               
    if(~isempty(pad))
        y=y(1+pad(1):1+pad(1)+original_size_r-1,1+pad(3):1+pad(3)+original_size_c-1,:,:);
    end

end




