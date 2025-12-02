process meteor_fastq{
  memory "12GB"
  cpus 2
  time '2h'
  container "sysbiojfgg/meteor2:v2.0.21"
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
  maxForks 25
  errorStrategy 'retry'
  maxRetries 2
  time '12h'
  container "sysbiojfgg/meteor2:v2.0.21"
  containerOptions "--bind ${workflow.homeDir}"
  publishDir "${params.output}" , mode: 'copy'


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
             --kf
      """

    }else { 
      """
      meteor mapping \\
             -i ${x.id} \\
             -r ${ref_dir} \\
             -o map \\
             -p end-to-end \\
             -t ${task.cpus} \\
             --kf
      """
    }
}

process meteor_profile{
  memory "6GB"
  cpus 1
  time '2h'
  container "sysbiojfgg/meteor2:v2.0.21"
  containerOptions "--bind ${workflow.homeDir}"
  publishDir "${params.output}" 


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
  container "sysbiojfgg/meteor2:v2.0.21"
  containerOptions "--bind ${workflow.homeDir}"
  publishDir "${params.output}/profile_dwsize" 

  input:
    path (mappings)
    path (ref_dir)
  output:
    tuple val(x), path("${x.id}_${params.downsize_cutoff}"), emit: profiled_samples

  script:
      filename= mappings.getSimpleName()
      x= [id : filename.tokenize("/")[-1]]

      """
      meteor profile \\
             -i ${x.id} \\
             -r ${ref_dir} \\
             -o ${x.id}_${params.downsize_cutoff} \\
             --seed ${params.seed} \\
             -n coverage \\
             -l ${params.downsize_cutoff}
      """

}


process meteor_merge{
  memory "6GB"
  cpus 1
  time '2h'
  container "sysbiojfgg/meteor2:v2.0.21"
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
             -i ${profile_dir} \\
             -r ${ref_dir} \\
             -o ${params.output} \\
             -p ${x.id} \\
             -s -g 
      """
}


process meteor_strain{
  memory "12GB"
  cpus 2
  time '4h'
  container "sysbiojfgg/meteor2:v2.0.21"
  containerOptions "--bind ${workflow.homeDir}"
  publishDir "${params.output}",  mode: 'copy' 

  input:
    path(mapped_dir)
    path(ref_dir)
  output:
    path("strain/${x.id}"), emit: strain_profiles

  script:
      filename= mapped_dir.getSimpleName()
      x= [id : filename.tokenize("/")[-1]]
      """
      meteor strain \\
             -i ${mapped_dir} \\
             -r ${ref_dir} \\
             -l 1 \\
             -m 50 \\
             -o strain \\
             -t ${task.cpus}
      """
}

process meteor_tree{
  memory "6GB"
  cpus 1
  time '2h'
  container "sysbiojfgg/meteor2:v2.0.21"
  containerOptions "--bind ${workflow.homeDir}"
  publishDir "${params.output}" 

  input:
    path (mutations)
  output:
    path("tree/*"), emit: strain_tree

  script:
      """
      meteor tree \\
             -i strain \\
             -o tree \\
             -t ${task.cpus}
      """
}