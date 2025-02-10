//import modules
include{fastp} from '../modules/fastp'
include{meteor_fastq} from '../modules/meteor'
include{meteor_map} from '../modules/meteor'
include{meteor_profile} from '../modules/meteor'
include{meteor_merge} from '../modules/meteor'
include{bowtie2_rmhost} from  '../modules/bowtie2'

workflow METEOR{
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
    host_genome = Channel.value(file( "${params.host_index}" ))
    fastp(ch_raw_short_reads)
    clean_reads = fastp.out.clean_reads

    bowtie2_rmhost(clean_reads, host_genome)
    reads_rmhost = bowtie2_rmhost.out.reads_rmhost

    //meteor_fastq(clean_reads)
    meteor_fastq(reads_rmhost)
    census_reads = meteor_fastq.out.census_reads

    meteor_map(census_reads, catalogue)
    mapreads=meteor_map.out.mapped_reads

    meteor_profile(mapreads, catalogue)
    profiled_samples=meteor_profile.out.profiled_samples

    meteor_merge(profiled_samples, catalogue)

    //readcount=meteor.out.readcount
    //report(readcount)

}

/*workflow METEOR_DOWNSIZE{
  meteor_maps=Channel.path("${params.meteor_out}")

  meteor_profile_downsize(meteor_maps)
  profiled_samples=meteor_profile_downsize.out.profiled_samples.collect()

  meteor_merge(profiled_samples)  
}
*/

