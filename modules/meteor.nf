process meteor_fastq{
  memory "20GB"
  cpus 2
  time '6h'
  container "sysbiojfgg/meteor2:v0.2"
  containerOptions "--bind ${workflow.homeDir}"
  publishDir "${params.output}/fq" 

  input:
    tuple val(x), path(reads)
  output:
    tuple val(x), path("${x.id}"), emit: census_reads

  script:
    if(x.single_end) {
      """
      meteor fastq \\
             -i . \\
             -m "${x.id}" \\
             -o . \\
             #-t ${task.cpus} \\
      """

    }else { 
      """
      zcat ${x.id}.1.fq.gz | head
      meteor fastq \\
             -i . \\
             -m "${x.id}" \\
             -o . \\
             -p \\
             # -t ${task.cpus} \\
      """
    }
}

process meteor_map{
  memory params.meteor_memory
  cpus params.meteor_threads
  time '12h'
  container "sysbiojfgg/meteor2:v0.2"
  containerOptions "--bind ${workflow.homeDir}"
  publishDir "${params.output}/map" 


  input:
    tuple val(x), path(reads)
    path(ref_dir)
  output:
    tuple val(x), path("map/${x.id}"), emit: mapped_reads

  script:
    if(x.single_end) {
      """
      meteor mapping \\
             -i ${x.id} \\
             -r ${ref_dir} \\
             -o map \\
             -t ${task.cpus} \\
      """

    }else { 
      """
      meteor mapping \\
             -i ${x.id} \\
             -r ${ref_dir} \\
             -o map \\
             -p end-to-end \\
             -t ${task.cpus} \\
      """
    }
}

process meteor_profile{
  memory "12GB"
  cpus 2
  time '2h'
  container "sysbiojfgg/meteor2:v0.2"
  containerOptions "--bind ${workflow.homeDir}"
  publishDir "${params.output}/profile" 


  input:
    tuple val(x), path(mappings)
    path (ref_dir)
  output:
    tuple val(x), path("profile/${x.id}"), emit: profiled_samples

  script:
      """
      meteor profile \\
             -i ${x.id} \\
             -r ${ref_dir} \\
             -o "profile" \\
             -n coverage
      """
}

process meteor_profile_downsize{
  memory "6GB"
  cpus 1
  time "6h"
  container "sysbiojfgg/meteor2:v0.2"
  containerOptions "--bind ${workflow.homeDir}"
  publishDir "${params.output}/profile_dwsize" 

  input:
    tuple val(x), path(mappings)
    val(params.cutoff)
  output:
    path("profile_dwsize_${x}_${params.downsize_cutoff}"), emit: profiled_samples

  script:
      """
      meteor profile \\
             -i map/${x.id} \\
             -r ${ref_dir} \\
             -o profile_dwsize_${x}_${params.downsize_cutoff} \\
             -seed ${params.seed} \\
             -n coverage \\
             -l ${params.downsize_cutoff}
      """
}



process meteor_merge{
  memory "48GB"
  cpus 2
  time '10h'
  container "sysbiojfgg/meteor2:v0.2"
  containerOptions "--bind ${workflow.homeDir}"
  publishDir "${params.output}/${x.id}"

  input:
    tuple val(x), path(profile_dir)
    path(ref_dir)
  output:
    path("${params.output}/${x.id}*"), emit: tables

  script:
      """
      meteor merge \\
             -i ${x.id} \\
             -r ${ref_dir} \\
             -o ${params.output} \\
             -p ${x.id} \\
             -s -g 
      
      """
}
