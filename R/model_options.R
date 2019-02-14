
# Create automation options for modelling execution
auto_options <- function(downsamp_seed
                        ,downsamp_perc
                        ,num_to_cat
                        ,cat_to_del
                        ,missing_perc){
options = list(downsamp_seed=downsamp_seed
                    ,downsamp_perc=downsamp_perc
                    ,num_to_cat=num_to_cat
                    ,cat_to_del=cat_to_del
                    ,missing_perc=missing_perc
                    )
return(options)
}