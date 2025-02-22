function [net,opts]=train_net(net,opts)

    opts.training=1;
    %{
    if strcmp(net.layers{end}.type,'softmax')
        net.layers{end}.type='softmaxloss'; 
    end
    %}
    
    if ~isfield(opts.parameters,'learning_method')
        opts.parameters.learning_method='sgd';
        
    end
    
    if ~isfield(opts,'display_msg')
        opts.display_msg=1; 
    end
    opts.MiniBatchError=[];
    opts.MiniBatchLoss=[];

    
    tic
    
    opts.order=randperm(opts.n_train);
    
    if opts.parameters.selective_sgd==1         
         [ net,opts ] = selective_sgd( net,opts );
    end

    
    for mini_b=1:opts.n_batch
                
        idx=opts.order(1+(mini_b-1)*opts.parameters.batch_size:mini_b*opts.parameters.batch_size);
        
        if length(size(opts.train))==2%%train mlp                    
            res(1).x=opts.train(:,idx);
        end
        
            
        if length(size(opts.train))==4%%train cnn
            res(1).x=opts.train(:,:,:,idx);
        end
                
        if isfield(opts,'train_labels')
            res(1).class=opts.train_labels(idx);
        end
        %forward
        
        
        [ net,res,opts ] = net_ff( net,res,opts );    
        
            
        %%%%backward
        opts.dzdy=single(1.0);        
        if opts.use_gpu
            opts.dzdy=gpuArray(single(opts.dzdy));
        end
        [ net,res,opts ] = net_bp( net,res,opts );
        
        
        
        %%summarize
        err=error_multiclass(res(1).class,res);
        err=gather(err);
        if opts.display_msg==1
            disp(['Minibatch error: ', num2str(err(1)./opts.parameters.batch_size),' Minibatch loss: ', num2str(res(end).x/opts.parameters.batch_size)])
        end
        opts.MiniBatchError=[opts.MiniBatchError;err(1)/opts.parameters.batch_size];
        opts.MiniBatchLoss=[opts.MiniBatchLoss;gather(res(end).x/opts.parameters.batch_size)]; 
        
        opts.PreviousLoss=opts.MiniBatchLoss(end);
        
        

  
         %%%%%%%%%%%%%%%%%%%% here comes to the updating part;
         if (~isfield(opts.parameters,'iterations'))
            opts.parameters.iterations=0; 
        end
        opts.parameters.iterations=opts.parameters.iterations+1;
        
        
        %apply gradients
        
        [  net,res,opts ] = opts.parameters.learning_method( net,res,opts );
        
    end
    
    opts.results.TrainEpochError=[opts.results.TrainEpochError;mean(opts.MiniBatchError(:))];
    opts.results.TrainEpochLoss=[opts.results.TrainEpochLoss;mean(opts.MiniBatchLoss(:))];
    
    if opts.RecordStats==1
        opts.results.TrainLoss=[opts.results.TrainLoss;opts.MiniBatchLoss];
        opts.results.TrainError=[opts.results.TrainError;opts.MiniBatchError]; 
    end
    
    toc;

end




