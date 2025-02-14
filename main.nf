// main workflow assembly SRA using megahit
nextflow.enable.dsl=2
include {METEOR} from './workflows/meteor2'
include {METEOR_DOWNSIZE} from './workflows/meteor2'

//run assembly pipeline
workflow NF_METEOR {
    if(!params.meteor_downsize){
        METEOR()
    }
    else{
        METEOR_DOWNSIZE()
    }
}

//WORKFLOW: Execute a single named workflow for the pipeline
workflow {
    NF_METEOR ()
}
