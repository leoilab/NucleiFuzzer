#!/bin/bash

# ASCII art
echo -e "\e[91m"
cat << "EOF"
                     __     _ ____                         
   ____  __  _______/ /__  (_) __/_  __________  ___  _____
  / __ \/ / / / ___/ / _ \/ / /_/ / / /_  /_  / / _ \/ ___/
 / / / / /_/ / /__/ /  __/ / __/ /_/ / / /_/ /_/  __/ /    
/_/ /_/\__,_/\___/_/\___/_/_/  \__,_/ /___/___/\___/_/   v1.0.1

                               Made by Satya Prakash (0xKayala)
EOF
echo -e "\e[0m"

# Help menu
display_help() {
    echo -e "NucleiFuzzer is a Powerful Automation tool for detecting XSS, SQLi, SSRF, Open-Redirect, etc. vulnerabilities in Web Applications\n\n"
    echo -e "Usage: $0 [options]\n\n"
    echo "Options:"
    echo "  -h, --help              Display help information"
    echo "  -d, --domain <domain>   Single domain to scan for XSS, SQLi, SSRF, Open-Redirect, etc. vulnerabilities"
    echo "  -f, --file <filename>   File containing multiple domains/URLs to scan"
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]
do
    key="$1"
    case $key in
        -h|--help)
            display_help
            ;;
        -d|--domain)
            domain="$2"
            shift
            shift
            ;;
        -f|--file)
            filename="$2"
            shift
            shift
            ;;
        *)
            echo "Unknown option: $key"
            display_help
            ;;
    esac
done

# Step 2: Ask the user to enter the domain name or specify the file
if [ -z "$domain" ] && [ -z "$filename" ]; then
    echo "Please provide a domain with -d or a file with -f option."
    display_help
fi

# Combined output file for all domains
output_file="output/allurls.txt"

# Step 3: Get the vulnerable parameters based on user input
if [ -n "$domain" ]; then
    echo "Running ParamSpider on $domain"
    paramspider -d "$domain" --exclude png,jpg,gif,jpeg,swf,woff,gif,svg --level high --quiet -o "output/$domain.txt"
    cat "output/$domain.txt" >> "$output_file"  # Append to the combined output file
elif [ -n "$filename" ]; then
    echo "Running ParamSpider on URLs from $filename"
    while IFS= read -r line; do
        paramspider -d "$line" --exclude png,jpg,gif,jpeg,swf,woff,gif,svg --level high --quiet -o "output/$line.txt"
        cat "output/$line.txt" >> "$output_file"  # Append to the combined output file
    done < "$filename"
fi

# Step 4: Check whether URLs were collected or not
if [ ! -s "output/$domain.txt" ] && [ ! -s "$output_file" ]; then
    echo "No URLs Found. Exiting..."
    exit 1
fi

# Step 5: Run the Nuclei Fuzzing templates on the collected URLs
echo "Running Nuclei on collected URLs"
if [ -n "$domain" ]; then
    cat "output/$domain.txt" | httpx -silent -mc 200,301,302,403 | nuclei -t "$home_dir/fuzzing-templates" -rl 05
elif [ -n "$filename" ]; then
    cat "$output_file" | httpx -silent -mc 200,301,302,403 | nuclei -t "$home_dir/fuzzing-templates" -rl 05
fi

# Step 6: End with a general message as the scan is completed
echo "Scan is completed - Happy Fuzzing"
