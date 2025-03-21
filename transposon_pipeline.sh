#!/bin/bash

# Step 1: Install Homebrew Without Admin Access
mkdir -p $HOME/tools
if [ ! -d "$HOME/tools/homebrew" ]; then
    git clone --depth=1 https://github.com/Homebrew/brew.git $HOME/tools/homebrew
fi

# Add Homebrew to PATH
echo 'export PATH=$HOME/tools/homebrew/bin:$PATH' >> ~/.zshrc
echo 'export HOMEBREW_PREFIX=$HOME/tools/homebrew' >> ~/.zshrc
echo 'export HOMEBREW_CELLAR=$HOME/tools/homebrew/Cellar' >> ~/.zshrc
echo 'export HOMEBREW_REPOSITORY=$HOME/tools/homebrew' >> ~/.zshrc
echo 'eval "$(\$HOME/tools/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc

# Verify Homebrew Installation
$HOME/tools/homebrew/bin/brew --version

# Step 2: Install Required Tools
$HOME/tools/homebrew/bin/brew install bowtie2 bwa samtools bedtools fastp

# Step 3: Verify Tools
bowtie2 --version
bwa
samtools --version
bedtools --version
fastp --version

# Step 4: Unzip Fastq Files
gunzip /Users/chaudharyp2/Downloads/GRS_0524/*.fastq.gz

# Step 5: Adapter Trimming with Fastp
mkdir -p /Users/chaudharyp2/Downloads/GRS_0524/trimmed
for file in /Users/chaudharyp2/Downloads/GRS_0524/LIB_*.fastq; do
    base=$(basename $file .fastq)
    fastp -i $file -o /Users/chaudharyp2/Downloads/GRS_0524/trimmed/${base}_trimmed.fastq \
          --html /Users/chaudharyp2/Downloads/GRS_0524/trimmed/${base}_fastp.html \
          --json /Users/chaudharyp2/Downloads/GRS_0524/trimmed/${base}_fastp.json
done

# Step 6: Index the Genome
bowtie2-build /Users/chaudharyp2/Downloads/GRS_0524/RmHV1_genome.fasta /Users/chaudharyp2/Downloads/GRS_0524/RmHV1_index

# Step 7: Align Trimmed Reads
mkdir -p /Users/chaudharyp2/Downloads/GRS_0524/mapped_genome
for file in /Users/chaudharyp2/Downloads/GRS_0524/trimmed/LIB_*_trimmed.fastq; do
    base=$(basename $file _trimmed.fastq)
    bowtie2 -p 8 -x /Users/chaudharyp2/Downloads/GRS_0524/RmHV1_index -U $file \
            -S /Users/chaudharyp2/Downloads/GRS_0524/mapped_genome/${base}_genome.sam
done

# Step 8: Convert SAM to Sorted BAM
mkdir -p /Users/chaudharyp2/Downloads/GRS_0524/sorted_bam
for file in /Users/chaudharyp2/Downloads/GRS_0524/mapped_genome/*_genome.sam; do
    base=$(basename $file _genome.sam)
    samtools view -bS $file | samtools sort -o /Users/chaudharyp2/Downloads/GRS_0524/sorted_bam/${base}_sorted.bam
done

# Step 9: Extract Mapped Sequences
mkdir -p /Users/chaudharyp2/Downloads/GRS_0524/mapped_sequences
for file in /Users/chaudharyp2/Downloads/GRS_0524/sorted_bam/*_sorted.bam; do
    base=$(basename $file _sorted.bam)
    samtools view -bF 4 $file > /Users/chaudharyp2/Downloads/GRS_0524/mapped_sequences/${base}_mapped.bam
done

# Step 10: Convert to BED Format
for file in /Users/chaudharyp2/Downloads/GRS_0524/mapped_sequences/*_mapped.bam; do
    base=$(basename $file _mapped.bam)
    bedtools bamtobed -i $file > /Users/chaudharyp2/Downloads/GRS_0524/mapped_sequences/${base}_mapped.bed
done

# Step 11: Extract Genomic Sequences
for file in /Users/chaudharyp2/Downloads/GRS_0524/mapped_sequences/*_mapped.bed; do
    base=$(basename $file _mapped.bed)
    bedtools getfasta -fi /Users/chaudharyp2/Downloads/GRS_0524/RmHV1_genome.fasta -bed $file \
                      -fo /Users/chaudharyp2/Downloads/GRS_0524/mapped_sequences/${base}_mapped_sequences.fasta
done

# Step 12: Identify Insertion Sites
mkdir -p /Users/chaudharyp2/Downloads/GRS_0524/insertion_sites
for file in /Users/chaudharyp2/Downloads/GRS_0524/mapped_sequences/*_mapped.bam; do
    base=$(basename $file _mapped.bam)
    bedtools bamtobed -i $file > /Users/chaudharyp2/Downloads/GRS_0524/insertion_sites/${base}_insertions.bed
done

echo "Pipeline execution complete!"

