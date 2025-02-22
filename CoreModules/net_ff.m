function [ net,res,opts ] = net_ff( net,res,opts )
%NET_FF Summary of this function goes here
%   Detailed explanation goes here

    
    if opts.use_gpu
        res(1).x=gpuArray(single(res(1).x));
    end
    
    for layer=1:numel(net.layers)

       
        opts.current_layer=layer;
        switch net.layers{layer}.type

            case 'conv'
                if isfield(net.layers{1,layer},'pad')
                    if(length(net.layers{1,layer}.pad)==1)
                        net.layers{1,layer}.pad=ones(1,4)*net.layers{1,layer}.pad;
                    end
                else
                   net.layers{1,layer}.pad=[];
                end
                
                if isfield(net.layers{1,layer},'stride')
                    if(length(net.layers{1,layer}.stride)==1)
                        net.layers{1,layer}.stride=ones(1,2)*net.layers{1,layer}.stride;
                    end
                else
                   net.layers{1,layer}.stride=1;
                end
                
                [res(layer+1).x,~,~,opts] = fast_conv_layer( res(layer).x,net.layers{1,layer}.weights{1},net.layers{1,layer}.weights{2},net.layers{1,layer}.stride,net.layers{1,layer}.pad,[],opts );
                
            case 'mlp'
                [res(layer+1).x,~,~] = fast_mlp_layer( res(layer).x,net.layers{1,layer}.weights{1},net.layers{1,layer}.weights{2},[] );

            case 'relu'
                res(layer+1).x = relu(res(layer).x,[] );
            case 'sigmoid'
                res(layer+1).x = sigmoid_ln(res(layer).x,[] );
            case 'tanh'
                res(layer+1).x = tanh_ln(res(layer).x,[] );
            
            case 'pad'
                res(layer+1).x = pad_data(res(layer).x,net.layers{1,layer}.pad,[]);

            case 'pool' 
                
                if isfield(net.layers{1,layer},'pad')
                    if(length(net.layers{1,layer}.pad)==1)
                        net.layers{1,layer}.pad=ones(1,4)*net.layers{1,layer}.pad;
                    end
                else
                   net.layers{1,layer}.pad=[];
                end
                
                if isfield(net.layers{1,layer},'S')
                   net.layers{1,layer}.stride=net.layers{1,layer}.S;
                end
                
                if isfield(net.layers{1,layer},'stride')
                    if(length(net.layers{1,layer}.stride)==1)
                        net.layers{1,layer}.stride=ones(1,2)*net.layers{1,layer}.stride;
                    end
                end
                
                
                
                if opts.training==1
                    [res(layer+1).x,res(layer+1).from] = maxpool(res(layer).x,net.layers{1,layer}.K,net.layers{1,layer}.stride,net.layers{1,layer}.pad,[],[],opts);
                else
                    [res(layer+1).x,~] = maxpool(res(layer).x,net.layers{1,layer}.K,net.layers{1,layer}.stride,net.layers{1,layer}.pad,[],[],opts);
                end
            case 'softmaxloss'
                if(length(size(res(layer).x))==2)%%mlp network
                   res(layer).x=permute(res(layer).x,[3,4,1,2]);
                end
                res(layer+1).x = vl_nnsoftmaxloss(res(layer).x, res(1).class) ;
            case 'softmax'                
                if(length(size(res(layer).x))==2)%%mlp network
                   res(layer).x=permute(res(layer).x,[3,4,1,2]);
                end
                res(layer+1).x = vl_nnsoftmax(res(layer).x) ;
           

        end
    end

end

