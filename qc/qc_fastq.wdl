version 1.0

struct Runtime {
    String gatk_docker
    File? gatk_override
    Int max_retries
    Int cpu
    Int machine_mem
    Int java_mem
    Int disk
    Int boot_disk_size
}

workflow qcFastq{

    input {
        Array[Pair[File, File]] fastq_files
        Boolean paired
    }

    call fastq2sam {}

}

task fastq2sam{
    input {
        File gatk
        Boolean asSAM
        Array[File] forward
        Array[File]? reverse
        String out_prefix
        String sample
        String? readGroup
        Runtime run_params
    }

    String outFN = if asSAM then out_prefix + ".sam" else out_prefix + ".bam"
    
    command <<<
        set -e

        input_fwd_files=${sep=' ' forward}
        if reverse; then
            input_rvs_files=${sep=' ' reverse}
        fi
        
        for i in ${!input_fwd_files[*]}
        do
            ~{gatk} --java-options "-Xmx~{run_params.java_mem}m" \
            FastqToSam \
            -F1=${input_fwd_files[$i]} \
            -O={outSAM} \
            -SM=~{sample} \
            -RG=~{readGroup}
            {-F2=${input_rvs_files[$i]} \
        done
    >>> 

    # Adapted from Broad workflows, but not running on GC so no preemptible
    runtime {
        docker: run_params.gatk_docker
        bootDiskSizeGb: run_params.boot_disk_size
        memory: run_params.machine_mem + " MB"
        disks: "local-disk " + run_params.disk + " HDD"
        maxRetries: run_params.max_retries
        cpu: run_params.cpu
    }

    output {
        File out_file = outFN
    }

}