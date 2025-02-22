function [opts]=test_net(net,opts)

    opts.training=0;
    if strcmp(net.layers{end}.type,'softmaxloss')
        %net.layers{end}.type='softmax'; 
    end

    opts.MiniBatchError=[];
    opts.MiniBatchLoss=[];
    
 
    
    for mini_b=1:opts.n_test_batch
        
        idx=1+(mini_b-1)*opts.parameters.batch_size:mini_b*opts.parameters.batch_size;

        if length(size(opts.test))==2%%test mlp                    
            res(1).x=opts.test(:,idx);
        else %test cnn
             res(1).x=opts.test(:,:,:,idx);
        end
        
        res(1).class=opts.test_labels(idx);

        [ net,res,opts ] = net_ff( net,res,opts );

    
        err=error_multiclass(res(1).class,res);    

        opts.MiniBatchError=[opts.MiniBatchError;gather(err(1)/opts.parameters.batch_size)];
        opts.MiniBatchLoss=[opts.MiniBatchLoss;gather(res(end).x/opts.parameters.batch_size)]; 
      
    end
    
    opts.results.TestEpochError=[opts.results.TestEpochError;mean(opts.MiniBatchError(:))];
    opts.results.TestEpochLoss=[opts.results.TestEpochLoss;mean(opts.MiniBatchLoss(:))];
      
end


