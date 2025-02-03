process meteor_fastq{
  memory "20GB"
  cpus 2
  time '6h'
  container "sysbiojfgg/meteor:V0.1"

  input:
    tuple val(x), path(reads)
  output:
    tuple val(x), path("census_fastq"), emit: census_reads

  script:
    if(x.single_end) {
      """
      meteor fastq \\
             -i ${reads} \\
             -o census_fastq \\
             -t ${task.cpus} \\
      """

    }else { 
      """
      meteor fastq \\
             -i ${reads} \\
             -o census_fastq \\
             -p \\
             -t ${task.cpus} \\
      """
    }
}

process meteor{
  memory params.meteor_memory
  cpus params.meteor_threads
  time '12h'
  container "sysbiojfgg/meteor:V0.1"

  input:
    tuple val(x), path(reads)
    path(ref_dir)
  output:
    tuple val(x), path("${x.id}."), emit: mapped_reads

  script:
    if(x.single_end) {
      """
      meteor mapping \\
             -i ${reads} \\
             -r ${ref_dir} \\
             -o out_dir \\
             -t ${task.cpus} \\
      """

    }else { 
      """
      meteor mapping \\
             -i ${reads} \\
             -r ${ref_dir} \\
             -o out_dir \\
             -p \\
             -t ${task.cpus} \\
      """
    }
}

process meteor_profile{
  memory "48GB"
  cpus 8
  time '6h'
  container "sysbiojfgg/meteor2:V0.1"

  input:
    path(mappings)
  output:
    path("meteor_profile"), emit: tables

  script:
      """
      meteor profile \\
             -i ${mappings} \\
             -o meteor_profile \\
      """
}

process meteor_merge{
  memory "48GB"
  cpus 2
  time '10h'
  container "sysbiojfgg/meteor2:V0.1"
  publishDir "meteor_output", mode: 'copy'

  input:
    path(mappings_dir)
    path(ref_dir)
  output:
    path("meteor_output"), emit: tables

  script:
      """
      mkdir project/
      mv ${mappings_dir} project/
      meteor merge \\
             -i project \\
             -r ${ref_dir} \\
             -o meteor_output \\
             -g 
      """
}
