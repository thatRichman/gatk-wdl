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
    if ( defined(fastq_2) ) {
        call fastq2bam_paired as convertedBam_pair {
            input:
                fastq_1 = fastq_1,
                fastq_2 = select_first([fastq_2, ""]), # might fail at runtime
                sample = sample,
                readGroup = readGroup,
                run_params = rt
        }
    }

    if ( !defined(fastq_2) ) {
        call fastq2bam_single as convertedBam_single {
            input:
                fastq_1 = fastq_1,
                sample = sample,
                readGroup = readGroup,
                run_params = rt
        }
    }


    output {
        File? converted_bam = if defined(fastq_2) then convertedBam_pair.uBAM else convertedBam_single.uBAM
    }
    
}

task fastq2bam_paired {
    input {
        String fastq_1
        String fastq_2
        String sample
        String? readGroup
        Runtime run_params
    }

    String outBAM = "~{readGroup}.unmapped.bam"
    
    command <<<
        set -e
        
        gatk --java-options "-Xmx~{run_params.java_mem_gb}g" \
        FastqToSam \
        -F1 ~{fastq_1} \
        -F2 ~{fastq_2} \
        -O ~{outBAM} \
        -SM ~{sample} \
        -RG ~{readGroup}
    >>> 

    runtime {
        docker: run_params.gatk_docker
    }

    output {
        File uBAM = "~{readGroup}.unmapped.bam"
    }

}

task fastq2bam_single {
    input {
        String fastq_1
        String sample
        String? readGroup
        Runtime run_params
    }

    String outBAM = "~{readGroup}.unmapped.bam"
    
    command <<<
        set -e
        
        gatk --java-options "-Xmx~{run_params.java_mem_gb}g" \
        FastqToSam \
        -F1 ~{fastq_1} \
        -O ~{outBAM} \
        -SM ~{sample} \
        -RG ~{readGroup}
    >>> 

    runtime {
        docker: run_params.gatk_docker
    }

    output {
        File uBAM = "~{readGroup}.unmapped.bam"
    }

}