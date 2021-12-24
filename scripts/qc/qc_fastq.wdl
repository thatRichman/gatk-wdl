version 1.0

struct Runtime {
    String gatk_docker
    Int java_mem_gb
}

workflow qcFastq{
    input {
        String fastq_1
        String? fastq_2
        String sample
        String readGroup
        String gatk_docker
        Int java_mem_gb
    }

    Runtime rt = {"gatk_docker": gatk_docker, "java_mem_gb": java_mem_gb}

    call fastq2bam as convertedBam{
        input:
            fastq_1 = fastq_1,
            fastq_2 = select_first([fastq_2, ""]),
            sample = sample,
            readGroup = readGroup,
            run_params = rt
    }

    output {
        File converted_bam = convertedBam.uBAM
    }
}

task fastq2bam {
    input {
        String fastq_1
        String? fastq_2
        String sample
        String? readGroup
        Runtime run_params
    }
    
    command <<<
        set -e
        
        gatk --java-options "-Xmx~{run_params.java_mem_gb}g" \
        FastqToSam \
        -F1=${fastq_1} \
        -O={outBAM} \
        -SM=~{sample} \
        {-RG=${readGroup} \
        {-F2=${fastq_2}
    >>> 

    runtime {
        docker: run_params.gatk_docker
    }

    output {
        File uBAM = "~{readGroup}.unmapped.bam"
    }

}