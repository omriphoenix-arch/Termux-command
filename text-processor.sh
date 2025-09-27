#!/data/data/com.termux/files/usr/bin/bash
# Text Processor - Advanced text manipulation and processing

echo "📝 TEXT PROCESSOR"
echo "================="

# Function to convert case
convert_case() {
    local input="$1"
    local case_type="$2"
    local output="$3"
    
    if [ -z "$input" ] || [ -z "$case_type" ]; then
        echo "❌ Error: Please provide input and case type."
        echo "Usage: convert_case <input> <case_type> [output]"
        echo "Case types: upper, lower, title, sentence"
        return 1
    fi
    
    if [ ! -f "$input" ]; then
        echo "❌ Error: Input file '$input' not found."
        return 1
    fi
    
    output=${output:-"${input%.*}_${case_type}.${input##*.}"}
    
    echo "🔄 Converting case: $case_type"
    
    case "$case_type" in
        upper)
            tr '[:lower:]' '[:upper:]' < "$input" > "$output"
            ;;
        lower)
            tr '[:upper:]' '[:lower:]' < "$input" > "$output"
            ;;
        title)
            sed 's/\b\(.\)/\u\1/g' "$input" > "$output"
            ;;
        sentence)
            sed 's/\. \(.\)/. \u\1/g; s/^\(.\)/\u\1/' "$input" > "$output"
            ;;
        *)
            echo "❌ Unknown case type: $case_type"
            return 1
            ;;
    esac
    
    echo "✅ Case conversion completed: $output"
}

# Function to find and replace text
find_replace() {
    local input="$1"
    local find_text="$2"
    local replace_text="$3"
    local output="$4"
    
    if [ -z "$input" ] || [ -z "$find_text" ]; then
        echo "❌ Error: Please provide input file and search text."
        echo "Usage: find_replace <input> <find> <replace> [output]"
        return 1
    fi
    
    if [ ! -f "$input" ]; then
        echo "❌ Error: Input file '$input' not found."
        return 1
    fi
    
    output=${output:-"${input%.*}_replaced.${input##*.}"}
    replace_text=${replace_text:-""}
    
    echo "🔍 Finding: '$find_text'"
    echo "🔄 Replacing with: '$replace_text'"
    
    # Count occurrences first
    local count=$(grep -o "$find_text" "$input" | wc -l)
    echo "📊 Found $count occurrences"
    
    if [ "$count" -gt 0 ]; then
        sed "s/$find_text/$replace_text/g" "$input" > "$output"
        echo "✅ Replace completed: $output"
    else
        echo "⚠️ No occurrences found to replace"
    fi
}

# Function to extract lines
extract_lines() {
    local input="$1"
    local start_line="$2"
    local end_line="$3"
    local output="$4"
    
    if [ -z "$input" ] || [ -z "$start_line" ]; then
        echo "❌ Error: Please provide input file and line numbers."
        echo "Usage: extract_lines <input> <start_line> [end_line] [output]"
        return 1
    fi
    
    if [ ! -f "$input" ]; then
        echo "❌ Error: Input file '$input' not found."
        return 1
    fi
    
    end_line=${end_line:-$start_line}
    output=${output:-"${input%.*}_lines_${start_line}_${end_line}.${input##*.}"}
    
    echo "📄 Extracting lines $start_line to $end_line"
    
    sed -n "${start_line},${end_line}p" "$input" > "$output"
    
    local extracted_count=$(wc -l < "$output")
    echo "✅ Extracted $extracted_count lines: $output"
}

# Function to merge files
merge_files() {
    local output="$1"
    shift
    local files=("$@")
    
    if [ -z "$output" ] || [ ${#files[@]} -eq 0 ]; then
        echo "❌ Error: Please provide output file and input files."
        echo "Usage: merge_files <output> <file1> <file2> ..."
        return 1
    fi
    
    echo "🔗 Merging ${#files[@]} files into: $output"
    
    > "$output"  # Clear output file
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            echo "Adding: $(basename "$file")"
            echo "--- Content from: $file ---" >> "$output"
            cat "$file" >> "$output"
            echo "" >> "$output"
        else
            echo "⚠️ File not found: $file"
        fi
    done
    
    local total_lines=$(wc -l < "$output")
    echo "✅ Merge completed: $total_lines lines in $output"
}

# Function to split file
split_file() {
    local input="$1"
    local lines_per_file="$2"
    local prefix="$3"
    
    if [ -z "$input" ] || [ -z "$lines_per_file" ]; then
        echo "❌ Error: Please provide input file and lines per file."
        echo "Usage: split_file <input> <lines_per_file> [prefix]"
        return 1
    fi
    
    if [ ! -f "$input" ]; then
        echo "❌ Error: Input file '$input' not found."
        return 1
    fi
    
    prefix=${prefix:-"${input%.*}_part_"}
    
    echo "✂️ Splitting file: $input"
    echo "📄 Lines per file: $lines_per_file"
    
    split -l "$lines_per_file" "$input" "$prefix"
    
    local parts_created=$(ls ${prefix}* 2>/dev/null | wc -l)
    echo "✅ Created $parts_created parts with prefix: $prefix"
}

# Function to count statistics
text_stats() {
    local input="$1"
    
    if [ -z "$input" ]; then
        echo "❌ Error: Please provide input file."
        echo "Usage: text_stats <input>"
        return 1
    fi
    
    if [ ! -f "$input" ]; then
        echo "❌ Error: Input file '$input' not found."
        return 1
    fi
    
    echo "📊 TEXT STATISTICS for: $input"
    echo "================================"
    
    local lines=$(wc -l < "$input")
    local words=$(wc -w < "$input")
    local chars=$(wc -c < "$input")
    local chars_no_spaces=$(tr -d ' \t\n' < "$input" | wc -c)
    
    echo "📄 Lines: $lines"
    echo "📝 Words: $words"
    echo "🔤 Characters (with spaces): $chars"
    echo "🔠 Characters (without spaces): $chars_no_spaces"
    
    # Average words per line
    if [ "$lines" -gt 0 ]; then
        local avg_words=$((words / lines))
        echo "📈 Average words per line: $avg_words"
    fi
    
    # Most frequent words
    echo ""
    echo "🏆 Top 10 most frequent words:"
    tr -cs '[:alnum:]' '\n' < "$input" | tr '[:upper:]' '[:lower:]' | sort | uniq -c | sort -nr | head -10 | nl
    
    # File size
    local size=$(du -sh "$input" | cut -f1)
    echo ""
    echo "💾 File size: $size"
}

# Function to remove duplicates
remove_duplicates() {
    local input="$1"
    local output="$2"
    local keep_order="$3"
    
    if [ -z "$input" ]; then
        echo "❌ Error: Please provide input file."
        echo "Usage: remove_duplicates <input> [output] [keep_order]"
        return 1
    fi
    
    if [ ! -f "$input" ]; then
        echo "❌ Error: Input file '$input' not found."
        return 1
    fi
    
    output=${output:-"${input%.*}_unique.${input##*.}"}
    
    echo "🔍 Removing duplicate lines from: $input"
    
    local original_lines=$(wc -l < "$input")
    
    if [ "$keep_order" = "true" ]; then
        # Keep original order (slower but preserves order)
        awk '!seen[$0]++' "$input" > "$output"
    else
        # Sort and remove duplicates (faster)
        sort "$input" | uniq > "$output"
    fi
    
    local unique_lines=$(wc -l < "$output")
    local removed=$((original_lines - unique_lines))
    
    echo "✅ Duplicates removed: $output"
    echo "📊 Original lines: $original_lines"
    echo "📊 Unique lines: $unique_lines"
    echo "📊 Duplicates removed: $removed"
}

# Function to format text
format_text() {
    local input="$1"
    local format_type="$2"
    local output="$3"
    
    if [ -z "$input" ] || [ -z "$format_type" ]; then
        echo "❌ Error: Please provide input file and format type."
        echo "Usage: format_text <input> <format_type> [output]"
        echo "Format types: trim, normalize_spaces, remove_empty, add_numbers"
        return 1
    fi
    
    if [ ! -f "$input" ]; then
        echo "❌ Error: Input file '$input' not found."
        return 1
    fi
    
    output=${output:-"${input%.*}_formatted.${input##*.}"}
    
    echo "✨ Formatting text: $format_type"
    
    case "$format_type" in
        trim)
            # Remove leading and trailing whitespace from each line
            sed 's/^[[:space:]]*//;s/[[:space:]]*$//' "$input" > "$output"
            ;;
        normalize_spaces)
            # Replace multiple spaces with single space
            sed 's/[[:space:]]\+/ /g' "$input" > "$output"
            ;;
        remove_empty)
            # Remove empty lines
            sed '/^[[:space:]]*$/d' "$input" > "$output"
            ;;
        add_numbers)
            # Add line numbers
            nl -ba "$input" > "$output"
            ;;
        *)
            echo "❌ Unknown format type: $format_type"
            return 1
            ;;
    esac
    
    echo "✅ Text formatting completed: $output"
}

# Main menu
echo ""
echo "Choose text processing option:"
echo "1. 🔤 Convert case (upper/lower/title/sentence)"
echo "2. 🔍 Find and replace text"
echo "3. ✂️ Extract specific lines"
echo "4. 🔗 Merge multiple files"
echo "5. 📄 Split file into parts"
echo "6. 📊 Text statistics and analysis"
echo "7. 🎯 Remove duplicate lines"
echo "8. ✨ Format text (trim/normalize/clean)"
echo "9. 🔤 Custom regex processing"
echo ""

read -p "Select option (1-9): " option

case $option in
    1)
        echo ""
        read -p "📁 Input file: " input
        echo "Case types: upper, lower, title, sentence"
        read -p "🔤 Case type: " case_type
        read -p "📁 Output file (optional): " output
        convert_case "$input" "$case_type" "$output"
        ;;
        
    2)
        echo ""
        read -p "📁 Input file: " input
        read -p "🔍 Text to find: " find_text
        read -p "🔄 Replace with: " replace_text
        read -p "📁 Output file (optional): " output
        find_replace "$input" "$find_text" "$replace_text" "$output"
        ;;
        
    3)
        echo ""
        read -p "📁 Input file: " input
        read -p "📄 Start line: " start_line
        read -p "📄 End line (optional): " end_line
        read -p "📁 Output file (optional): " output
        extract_lines "$input" "$start_line" "$end_line" "$output"
        ;;
        
    4)
        echo ""
        read -p "📁 Output file: " output
        echo "Enter input files (one per line, empty line to finish):"
        files=()
        while IFS= read -r file && [ -n "$file" ]; do
            files+=("$file")
        done
        merge_files "$output" "${files[@]}"
        ;;
        
    5)
        echo ""
        read -p "📁 Input file: " input
        read -p "📄 Lines per file: " lines_per_file
        read -p "📁 Prefix for parts (optional): " prefix
        split_file "$input" "$lines_per_file" "$prefix"
        ;;
        
    6)
        echo ""
        read -p "📁 Input file: " input
        text_stats "$input"
        ;;
        
    7)
        echo ""
        read -p "📁 Input file: " input
        read -p "📁 Output file (optional): " output
        read -p "🔄 Keep original order? (y/n): " keep_order
        if [[ $keep_order =~ ^[Yy]$ ]]; then
            remove_duplicates "$input" "$output" "true"
        else
            remove_duplicates "$input" "$output" "false"
        fi
        ;;
        
    8)
        echo ""
        read -p "📁 Input file: " input
        echo "Format types: trim, normalize_spaces, remove_empty, add_numbers"
        read -p "✨ Format type: " format_type
        read -p "📁 Output file (optional): " output
        format_text "$input" "$format_type" "$output"
        ;;
        
    9)
        echo ""
        read -p "📁 Input file: " input
        read -p "🔧 Regex pattern: " pattern
        read -p "🔄 Replacement (optional): " replacement
        read -p "📁 Output file (optional): " output
        
        output=${output:-"${input%.*}_regex.${input##*.}"}
        
        if [ -n "$replacement" ]; then
            sed "s/$pattern/$replacement/g" "$input" > "$output"
            echo "✅ Regex replacement completed: $output"
        else
            grep "$pattern" "$input" > "$output"
            echo "✅ Regex extraction completed: $output"
        fi
        ;;
        
    *)
        echo "❌ Invalid option selected"
        exit 1
        ;;
esac

echo ""
echo "📝 Text processing completed!"
echo ""
echo "💡 Tips:"
echo "   - Always backup original files before processing"
echo "   - Use text statistics to understand your data"
echo "   - Combine operations for complex text processing"
echo "   - Regular expressions are powerful for pattern matching"