//import modules
//include{alientrimmer} from '../modules/alientrimmer'
include{fastp} from '../modules/fastp'
include{meteor_fastq} from '../modules/meteor'
include{meteor} from '../modules/meteor'
include{report} from '../modules/report'
include{meteor_merge} from '../modules/meteor'

workflow MAP{
    //read fastq sequences paired end or single end and save into channel
    Channel
    .fromFilePairs(params.input, size: params.single_end ? 1 : 2)
    .ifEmpty { exit 1, "Cannot find any reads matching: ${params.input}\n NB: Path needs to be enclosed in quotes!\nIf this is single-end data, please specify --single_end on the command line." }
    .map { row ->
                  def meta = [:]
                  meta.id           = row[0]
                  meta.group        = 0
                  meta.single_end   = params.single_end
                  return [ meta, row[1] ]
                }
    .set { ch_raw_short_reads }
    catalogue = Channel.value(file( "${params.catalogue}" ))
    fastp(ch_raw_short_reads)
    clean_reads = fastp.out.clean_reads

    //remove host reads provide genome reference as fasta file
    //host_genome = Channel.value(file( "${params.host_genome}" ))
    //bowtie2_rmhost(clean_reads, host_genome)
    //clean_reads_rmhost = bowtie2_rmhost.out.clean_reads

    meteor_fastq(clean_reads, catalogue)
    census_reads = meteor_fastq.out.census_reads

    meteor(census_reads, catalogue)
    mapreads=meteor.out.mapped_reads.collect()

    meteor_profile(mapreads)
    profiled_samples=meteor_profile.out.profiled_samples

    meteor_merge(profiled_samples)

    //readcount=meteor.out.readcount
    //report(readcount)

}



