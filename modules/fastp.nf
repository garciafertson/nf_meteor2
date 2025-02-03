process fastp{
  memory '6GB'
  cpus '1'
  time '5h'
  container "biocontainers-fastp-v0.20.1_cv1"

  input:
    tuple val(x), path(reads)
  output:
    tuple val(x), path("${x.id}*.fq.gz"), emit: clean_reads

  script:
    if(x.single_end) {
      """
      fastp -i ${reads} \\
            -o ${x.id}.trim.fq.gz \\
            --thread 1
      """

    }else { 
      """
      fastp --in1 ${reads[0]} \\
            --in2 ${reads[1]} \\
            --out1 "${x.id}.trim.1.fq.gz" \\
            --out2 "${x.id}.trim.2.fq.gz" \\
            --thread 1
      """
    }
}
