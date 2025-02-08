
process bowtie2_rmhost {
    //directives
    publishDir "${params.output}/bowtie2_remove_host"
    container "ummidock/bowtie2_samtools:1.0.0-2"
    cpus params.bwtcores
    memory '24 GB'
    time 6.h

    input:
      tuple val(x), path(reads)
      path index

    output:
      tuple val(x), path("*.unmapped*.fastq.gz") , emit: reads_rmhost
      path  "*.mapped*.read_ids.txt", optional:true , emit: read_ids
      tuple val(x), path("*.bowtie2.log")        , emit: log

    script:
      def args = task.ext.args ?: ''
      def args2 = task.ext.args2 ?: ''
      def prefix = task.ext.prefix ?: "${x.id}"
      def btidx= task.ext.prefix ?: "${index.getSimpleName()}"
      //def save_ids = (args2.contains('--host_removal_save_ids')) ? "Y" : "N"
      if (!x.single_end){
          """
          echo ${btidx}
          bowtie2 -p ${task.cpus} \\
                  -1 "${reads[0]}" -2 "${reads[1]}"  ${args2}\\
                  -x ${btidx}/${btidx} \\
                  --un-conc-gz ${prefix}.unmapped_%.fastq.gz \\
                  --al-conc-gz ${prefix}.mapped_%.fastq.gz \\
                  1> /dev/null \\
                  2> ${prefix}.bowtie2.log
          gunzip -c ${prefix}.mapped_1.fastq.gz | awk '{if(NR%4==1) print substr(\$0, 2)}' | LC_ALL=C sort > ${prefix}.mapped_1.read_ids.txt
          gunzip -c ${prefix}.mapped_2.fastq.gz | awk '{if(NR%4==1) print substr(\$0, 2)}' | LC_ALL=C sort > ${prefix}.mapped_2.read_ids.txt
          rm -f ${prefix}.mapped_*.fastq.gz
          """
      } else {
          """
          bowtie2 -p ${task.cpus} \\
                  -x ${btidx}/${btidx} \\
                  -U ${reads} ${args}\\
                  --un-gz ${prefix}.unmapped.fastq.gz \\
                  --al-gz ${prefix}.mapped.fastq.gz \\
                  1> /dev/null \\
                  2> ${prefix}.bowtie2.log
          gunzip -c ${prefix}.mapped.fastq.gz | awk '{if(NR%4==1) print substr(\$0, 2)}' | LC_ALL=C sort > ${prefix}.mapped.read_ids.txt
          rm -f ${prefix}.mapped.fastq.gz

          """
        // -x ${index[0].getSimpleName()} \\

      }
}
