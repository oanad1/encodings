%include "include/io.inc"

extern atoi
extern printf
extern exit

; Functions to read/free/print the image.
; The image is passed in argv[1].
extern read_image
extern free_image
; void print_image(int* image, int width, int height);
extern print_image

; Get image's width and height.
; Store them in img_[width, height] variables.
extern get_image_width
extern get_image_height

section .data
	use_str db "Use with ./tema2 <task_num> [opt_arg1] [opt_arg2]", 10, 0
        known_str db "revient"
        insert_str db "C'est un proverbe francais."
        comma db '-', '-', '.', '.', '-', '-', 0
        alphabet db '.', '-', 0, 0, '-', '.', '.', '.', '-', '.', '-', '.', '-', '.', '.', 0, '.', 0, 0, 0, '.', '.', '-', '.','-', '-', '.', 0, '.', '.', '.', '.', '.', '.', 0, 0, '.', '-', '-', '-', '-', '.', '-', 0, '.', '-', '.', '.', '-', '-', 0, 0, '-', '.', 0, 0, '-', '-', '-', 0,'.', '-', '-', '.', '-', '-', '.', '-', '.', '-', '.', 0,'.', '.', '.', 0, '-', 0, 0, 0, '.', '.', '-', 0,'.', '.', '.', '-', '.', '-', '-', 0, '-', '.', '.', '-', '-', '.', '-', '-', '-', '-', '.', '.', 0 

section .bss
    task:       resd 1
    img:        resd 1
    img_width:  resd 1
    img_height: resd 1

section .text
global main

    ;TASK 1 FUNCTIONS 
reset_known_str:
    xor edx, edx
    jmp check_match
    
bruteforce_singlebyte_xor:
    push ebp
    mov ebp, esp    
    
    ;Use ebx to try all keys from 0 to 255
    xor ebx, ebx
    
try_bruteforce_key:
    ;Save the address for the beginning of the matrix in eax
    mov ecx, [ebp + 8]
    mov eax, [ecx]
    
    ;Use ecx as the current row index
    xor ecx, ecx
    
task1_row_traversal:
    ;Save the current row index on the stack
    push ecx
    
    ;Store the current column index in ecx 
    xor ecx, ecx
    
    ;Store in edx the index of the last byte reached in "revient" 
    xor edx, edx
    
task1_column_traversal: 
    ;Save the key on the stack
    push ebx
    
    ;Get the decrypted value of the current byte
    xor bl, byte[eax]
    
    ;Move to the next byte 
    add eax, 4 
    
    ;Compare the current byte to the byte reached in "revient"
    cmp bl, byte[known_str + edx]
    
    ;In case of mismatch, start over from the beginning of the word
    jne reset_known_str
    inc edx

 check_match: 
    ;If all characters of "revient" were matched, then a valid decryption was found 
    cmp edx, 7 
    je found_decryption
    
    ;Recover key value
    pop ebx 
    
    ;Move on to the next column index until reaching the end of the row
    inc ecx
    cmp ecx, dword[img_width]
    jne task1_column_traversal 
    
    ;Recover the row number and increment it as to move on to the next row 
    pop ecx 
    inc ecx 
    
    ;If the row number is equal to the number of rows, the iteration is over 
    cmp ecx, dword[img_height]
    jne task1_row_traversal 
    
    ;Try the next key until reaching the byte limit of 255
    inc ebx
    xor eax, eax
    cmp ebx, 256
    jne try_bruteforce_key   
    jmp decryption_not_found
    
found_decryption:
    ;Get the key from the stack 
    pop ebx 
    
    ;Get the line number from the stack 
    pop edx
    
    ;Place the result in eax: the line number in the first 16 bits, key in al 
    mov ax, dx
    shl eax, 16
    mov al, bl
    
decryption_not_found:    
    leave 
    ret    

task1_print: 
    push ebp
    mov ebp, esp 
 
    ;Put the return value of bruteforce_singlebyte_xor in ebx
    ;bl has the key, edx has the line number  
    mov ebx, [ebp + 12]
    mov edx, ebx 
    shr edx, 16 
    push edx 
    
    ;Get to the beginning of the line where the string was found
    ;The base address for the line is: img + line_number * img_width * 4 
    mov eax, 4 
    mul edx
    mov edx, eax
    mov eax, [img_width]
    mul edx
    mov edx, eax
    
    ;Place the starting address for the img matrix in eax 
    mov ecx, [ebp + 8]
    mov eax, [ecx]
    add eax, edx  
    xor ecx, ecx 
    xor edx, edx

task1_print_str: 
    ;Decrypt and print each character starting from the beginning of the
    ;current line until reaching null or the end of the line 
    push ebx 
    xor bl, byte[eax]
    mov dl, bl
    pop ebx 
    cmp dl, 0
    je task1_print_line
    PRINT_CHAR dl 
    add eax, 4 
    inc ecx
    cmp ecx, [img_width]
    jne task1_print_str 
    
task1_print_line:   
    NEWLINE
    pop edx 
    
    ;Print the key and the line number where the string was found                      
    PRINT_DEC 1, bl
    NEWLINE
    PRINT_DEC 4, edx
    leave 
    ret    
    
    
   ;TASK 2 FUNCTIONS 
xor_encryption: 
    push ebp
    mov ebp, esp  
    
    ;Put the addres of the first value in img at eax 
    mov ecx, [ebp + 8]
    mov eax, [ecx]
    
    ;Put the return value of bruteforce_singlebyte_xor in ebx
    ;bl has the key, edx has the line number where the message was found
    mov ebx, [ebp + 12]
    mov edx, ebx 
    shr edx, 16 
    
    ;Get the line where the new string should be inserted
    inc edx
    
    ;Use ecx to store the total number of values in the matrix 
    push eax 
    push edx
    mov eax, dword[img_width]
    mul dword[img_height]
    mov ecx, eax  
    pop edx
    pop eax
    push ecx
    push eax
   
decode_elem: 
    ;Use the old key to decode the image 
    xor byte[eax], bl 
    add eax, 4 
    dec ecx
    jnz decode_elem 

get_start_address:   
    ;Get to the beginning of the line where the string should be inserted
    ;The base address for the line is: img + line_number * img_width * 4 
    mov eax, 4 
    mul edx
    mov edx, eax
    mov eax, [img_width]
    mul edx
    mov edx, eax
   
    ;Put the address where the string should be inserted in eax 
    pop eax
    push eax
    add eax, edx 
    
    ;Put the length of the string in ecx 
    mov ecx, 27
    xor edx, edx
    
    ;Save ebx on the stack
    push ebx 
    xor ebx, ebx
    
add_string: 
    ;Clear the current value 
    mov dword[eax], 0
    
    ;Add a character from the string to img 
    mov bl, byte[insert_str + edx]
    mov byte[eax], bl 
    
    ;Move to the next character in the string and to the next value in img 
    inc edx
    add eax, 4
    dec ecx
    cmp ecx, 0
    jne add_string
    
    ;Add the null terminator
    mov byte[eax],0

get_new_key:  
    ;The old key is in bl  
    pop ebx

    ;Multiply old_key by 2, add 3, divide by 5 and substract 4
    shl bl, 1
    add bl, 3 
    xor eax, eax
    mov al, bl
    mov bl, 5
    div bl
    mov bl, al
    sub bl, 4
   
    ;Get the address of the first value in img
    pop eax 
    
    ;Get the total number of values in img 
    pop ecx
   
encode_elem:
    ;Encode the image with the new key
    xor byte[eax], bl 
    add eax, 4 
    dec ecx
    jnz encode_elem 
    
new_img: 
    ;Print the image 
    push dword[img_height]
    push dword[img_width]
    push dword[img]
    call print_image
    add esp, 12
    leave 
    ret
    
    
    ;TASK 3 FUNCTIONS    
insert_symbols:
    push ebp
    mov ebp, esp 
    
    ;bl contains the symbol to be inserted: '.' or '-'
    mov ebx, [ebp + 16]
    
    ;eax cotains the img address
    mov eax, [ebp + 12]
    
    ;dl contains the number of symbols to be inserted 
    mov edx, [ebp + 8] 
    
put_symbol:
    ;Insert [dl] symbols at address eax 
    mov dword[eax], 0 
    mov byte[eax], bl
    add eax, 4
    dec dl
    jnz put_symbol
    leave
    ret 
     
morse_encrypt:
    push ebp
    mov ebp, esp   
    
    ;Convert the the index of insertion into an integer 
    push dword[ebp + 16]
    call atoi
    add esp, 4
    
    ;eax now has the integer offset (in dwords) from the beginning 
    ;of img up to the place of insertion 
    mov ecx, 4
    
    ;To get the offset in bytes, multiply eax by 4 
    mul ecx 

    ;Save the address of the img matrix in ecx 
    mov ebx, [ebp + 8]
    mov ecx, [ebx]
    
    ;Save the address for the beginning of insertion in eax 
    add eax, ecx 
    
    ;Save the adress for the first character of the string in ebx
    mov ebx, [ebp + 12]
    
encode_char: 
    cmp byte[ebx], ',' 
    jne nr_0_5 
    xor ecx, ecx
    
encode_comma:
    ;If the character is ',', use the encryption stored in variable comma 
    mov dword[eax],0
    xor edx, edx
    mov dl, byte[comma + ecx]
    mov byte[eax], dl
    inc ecx 
    add eax, 4
    cmp ecx, 6
    jne encode_comma 
    jmp end_char
     
nr_0_5:  
    ;If the character is not A..Z or 0..9 or ',', the encoding is not possible
    cmp byte[ebx], 48 
    jl end_morse_encoding 
       
    ;Case 0-5: 47 < character < 54
    cmp byte[ebx], 53
    jg nr_6_9
   
    ;INSERT DOTS 
    ;The number of dots in the encoding of char is (ASCII_code_of_char - 48)
    xor edx, edx  
    mov dl, byte[ebx]
    
    ;Store in dl the number of dots to be inserted
    sub dl, 48 
    
    ;Preserve register ebx
    push ebx
        
    ;Put in cl the symbol to be inserted 
    xor ecx, ecx 
    mov cl, '.'
    
    ;Insert [dl] dots at address eax
    ;The position eax is updated inside the function insert_symbols  
    push ecx
    push eax
    push edx
    call insert_symbols
    add esp, 12
    
    ;Recover register ebx
    pop ebx
    
    ;INSERT DASHES 
    ;The number of dashes in the encoding of char is (53 - ASCII_code_of_char)
    xor edx, edx
    mov dl, 53
    
    ;Store in dl the number of dashes to be inserted 
    sub dl, byte[ebx]
    
    ;Preserve register ebx
    push ebx
    
    ;Put in cl the symbol to be inserted 
    xor ecx, ecx 
    mov cl, '-'
    
    ;Insert [dl] dashes at address eax
    push ecx
    push eax
    push edx
    call insert_symbols
    add esp, 12 
    
    ;Recover register ebx
    pop ebx
    jmp end_char
    
nr_6_9:
    ;Case 6-9: 53 < character < 58
    cmp byte[ebx], 57
    jg uppercase
    
    ;INSERT DASHES 
    ;The number of dashes in the encoding of char is (ASCII_code_of_char - 53)
    xor edx, edx 
    mov dl, byte[ebx]
    
    ;Store in dl the number of dashes to be inserted 
    sub dl, 53
    
    ;Preserve register ebx
    push ebx
    
    ;Put in cl the symbol to be inserted 
    xor ecx, ecx 
    mov cl, '-'
    
    ;Insert [dl] dashes at address eax
    push ecx
    push eax
    push edx
    call insert_symbols
    add esp, 12 
    
    ;Recover register ebx
    pop ebx
    
    ;INSERT DOTS
    ;The number of dots in the encoding of char is (58 - ASCII_code_of_char) 
    xor edx, edx
    mov dl, 58
    
    ;Store in dl the number of dots to be inserted
    sub dl, byte[eax]
    
    ;Preserve register ebx
    push ebx
    
    ;Put in cl the symbol to be inserted 
    xor ecx, ecx 
    mov cl, '.'
    
    ;Insert [dl] dots at address eax
    push ecx
    push eax
    push edx
    call insert_symbols
    add esp, 12 
    
    ;Recover registers 
    pop ebx
    jmp end_char
    
uppercase:
    ;If the character is not an uppercase letter when reaching
    ;this point, the encoding is not possible 
    cmp byte[ebx], 65
    jl end_morse_encoding
    cmp byte[ebx], 90
    jg end_morse_encoding
    
    ;Get the character's position in the Morse alphabet
    ;Each letter has 4 bytes reserved for its encoding symbols 
    ;The position is: (ASCII_code_of_char - 65)* 4
    push eax
    xor edx, edx
    mov dl, byte[ebx]
    sub dl, 65 
    mov eax, 4
    mul edx 
    mov edx, eax
    pop eax
    
    ;Store in edx the position in the Morse alphabet
    add edx, alphabet  
    xor ecx, ecx
    push ebx
     
encode_uppercase:
    ;Clear 4 bytes in eax and place the symbol on the first byte
    mov dword[eax],0
    xor ebx, ebx
    mov bl, byte[edx]
    
    ;In case the letter is encoded using less than 4 symbols 
    cmp bl, 0
    je end_uppercase_encoding
    mov byte[eax], bl
    
    ;Advance a dword into img and a byte into the alphabet 
    add eax, 4
    add edx, 1
    
    ;Repeat for all 4 bytes in the letter's encoding  
    inc ecx
    cmp ecx, 4
    jne encode_uppercase

end_uppercase_encoding:
    pop ebx         
    
end_char:
    ;Add space after adding a character 
    mov dword[eax], 0 
    mov byte[eax], ' '
    add eax, 4
    
    ;Move on to the next character in the string and check if it's null 
    inc ebx
    cmp byte[ebx], 0
    jne encode_char
    
end_morse_encoding:
    ;Terminate the string by null 
    sub eax, 4
    mov dword[eax], 0 
    
    ;Print the image 
    push dword[img_height]
    push dword[img_width]
    push dword[img]
    call print_image
    add esp, 12
    leave 
    ret
    
    
    ;TASK 4 FUNCTIONS   
lsb_encode:
    push ebp
    mov ebp, esp   
    
    ;Convert the the index of insertion into an integer 
    push dword[ebp + 16]
    call atoi
    add esp, 4
    
    ;eax now has the integer offset (in dwords) from the beginning 
    ;of img up to the place of insertion
    dec eax
    mov ecx, 4
    
    ;To get the offset in bytes, multiply eax by 4 
    mul ecx 

    ;Save the address of the img matrix in ecx 
    mov ebx, [ebp + 8]
    mov ecx, [ebx]
    
    ;Save the address for the beginning of insertion in eax 
    add eax, ecx 
    
    ;Save the adress for the first character of the string in ebx
    mov ebx, [ebp + 12]

insert_byte: 
    xor ecx, ecx
    
insert_bit:
    xor edx, edx
    mov dl, byte[ebx] 
    
    ;Bring the bit of index ecx (beginning from MSB) to MSB position  
    shl dl, cl
    
    ;Clear all bits except the MSB 
    and dl, 10000000b
   
    ;If the number became 0 due to the previous operation,
    ;we know that the bit we are currently analyzing is 0 
    cmp dl, 0
    jne msb_1
 
    ;If the bit is 0, make the LSB from the current img position 0 
    and byte[eax], 11111110b
    jmp next_bit
    
msb_1:
    ;If the bit is 1, make the LSB from the current img position 1
    or byte[eax], 00000001b
    
next_bit:
    ;Move on to the next dword in img 
    add eax, 4
    
    ;Move on to the next bit in the current char
    inc cl 
    cmp cl, 8
    jne insert_bit

    ;Move on to the next character until reaching  
    ;an iteration which involves a null character 
    cmp byte[ebx], 0
    je end_lsb_encode
    inc ebx
    jmp insert_byte
       
end_lsb_encode:
    ;Print the image 
    push dword[img_height]
    push dword[img_width]
    push dword[img]
    call print_image
    add esp, 12
    leave 
    ret
  
  
    ;TASK 5 FUNCTIONS   
lsb_decode:
    push ebp
    mov ebp, esp
      
    ;Convert the the byte index into an integer 
    push dword[ebp + 12]
    call atoi
    add esp, 4
    dec eax
    mov ecx, 4
    
    ;To get the offset in bytes, multiply eax by 4 
    mul ecx 

    ;Save the first address of the img matrix in ecx 
    mov ebx, [ebp + 8]
    mov ecx, [ebx]
    
    ;Save the start address for the string in eax 
    add eax, ecx 
    
decode_char:
    ;Decode groups of 8 bits and convert them to characters
    ;Use cl to keep track of the current bit index 
    mov cl, 7
    xor ebx, ebx
     
decode_bit:
    ;Use dl to process each byte from img 
    xor edx, edx
    mov dl, byte[eax]
    add eax, 4
    
    ;Clear all bits except LSB
    and dl, 00000001b
    
    ;Place each bit in its coresponding position
    ;Equivalent to calculating 2^(bit_position)
    shl dl, cl
    
    ;Store the final result in bl 
    add bl, dl
    
    ;Stop after 8 iterations 
    cmp cl, 0
    je print_char
    dec cl
    jmp decode_bit

print_char:  
    ;When the last decoded character is null, exit loop  
    cmp bl,0
    je end_lsb_decode 
    
    ;Print each decoded character 
    PRINT_CHAR bl
    jmp decode_char
    
end_lsb_decode:
    NEWLINE   
    leave 
    ret
      
      
    ;TASK 6 FUNCTIONS   
blur:
    push ebp
    mov ebp, esp
    
    ;Calculate and store in ebx the offset between a matrix element 
    ;and the values placed directly on top/under it 
    mov eax, 4
    mul dword[img_width]
    mov ebx, eax
    
    ;Use eax to save the adress of the first element in the matrix 
    mov ecx, [ebp + 8]
    mov eax, [ecx]
   
    ;Use ecx to iterate through all matrix rows except the first and last
    ;ecx - 2...[img_height]-1
    mov ecx, 2
    
    ;Start from the second row 
    add eax, ebx
    
task6_row_traversal: 
    ;Use edx to iterate through all matrix columns except the first and last
    ;edx - 2...[img_width]-1
    mov edx, 2
    
    ;Skip the first element on the row 
    add eax, 4 
    
    ;Save ecx on the stack
    push ecx
    
task6_column_traversal:
     xor ecx, ecx

    ;Save edx on the stack
    push edx
     
    ;Place the current element in cl
    mov cl, byte[eax]
    mov edx, ecx 
    
    ;Add the value from its left
    sub eax, 4
    mov cl, byte[eax]
    add edx, ecx
    
    ;Add the value from its right  
    add eax, 8
    mov cl, byte[eax]
    add edx, ecx
    
    ;Return to the current position
    sub eax, 4
    
    ;Add the value from its top
    sub eax, ebx 
    mov cl, byte[eax]
    add edx, ecx
    
    ;Add the value below it 
    add eax, ebx 
    add eax, ebx
    mov cl, byte[eax]
    add edx, ecx 

    ;Return to the current position and save it on the stack
    sub eax, ebx 
    push eax 

    ;Calculate the avarage for the current element 
    mov ecx, 5
    mov eax, edx
    xor edx, edx
    div ecx
    mov ecx, eax  
       
    ;Place the avarage on the empty byte next to our value  
    pop eax
    mov byte[eax + 1], cl
    
    pop edx

    ;Move on to the next value in img 
    add eax, 4 
    inc edx 
    cmp edx, [img_width]
    jne task6_column_traversal
    
    ;Skip the last value on the row 
    add eax, 4
    pop ecx
    inc ecx 
    cmp ecx, [img_height]
    jne task6_row_traversal 
    
update_values: 
    ;Return to the beginning of img 
    mov ecx, [ebp + 8]
    mov eax, [ecx]
   
    ;Use ecx to iterate through all matrix rows except the first and last
    ;ecx - 2...[img_height]-1
    mov ecx, 2
    
    ;Start from the second row 
    add eax, ebx
    
blur_all_rows: 
    ;Use edx to iterate through all matrix columns except the first and last
    ;edx - 2...[img_width]-1
    mov edx, 2
    
    ;Skip the first element on the row 
    add eax, 4 
    
blur_row:
    ;Save edx on the stack 
    push edx
     
    ;Copy the second byte(the avarage) into the first (the old value)
    xor edx, edx 
    mov dl, byte[eax + 1]
    mov byte[eax], dl
     
    ;Clear the second byte
    mov byte[eax + 1], 0
     
    ;Restore column iterator
    pop edx

    ;Move on to the next value in img 
    add eax, 4 
    inc edx 
    cmp edx, [img_width]
    jne blur_row
    
    ;Skip the last value on the row 
    add eax, 4
    inc ecx 
    cmp ecx, [img_height]
    jne blur_all_rows
    
end_blur:
    ;Print the image 
    push dword[img_height]
    push dword[img_width]
    push dword[img]
    call print_image
    add esp, 12
    leave 
    ret
      
main:
    ; Prologue
    ; Do not modify!
    push ebp
    mov ebp, esp

    mov eax, [ebp + 8]
    cmp eax, 1
    jne not_zero_param

    push use_str
    call printf
    add esp, 4

    push -1
    call exit

not_zero_param:
    ; We read the image. You can thank us later! :)
    ; You have it stored at img variable's address.
    mov eax, [ebp + 12]
    push DWORD[eax + 4]
    call read_image
    add esp, 4
    mov [img], eax

    ; We saved the image's dimensions in the variables below.
    call get_image_width
    mov [img_width], eax

    call get_image_height
    mov [img_height], eax

    ; Let's get the task number. It will be stored at task variable's address.
    mov eax, [ebp + 12]
    push DWORD[eax + 8]
    call atoi
    add esp, 4
    mov [task], eax 

    ; There you go! Have fun! :D

    mov eax, [task] 
    cmp eax, 1
    je solve_task1
    cmp eax, 2
    je solve_task2
    cmp eax, 3
    je solve_task3
    cmp eax, 4
    je solve_task4
    cmp eax, 5
    je solve_task5
    cmp eax, 6
    je solve_task6
    jmp done
    

solve_task1: 
    push img
    call bruteforce_singlebyte_xor  
    add esp, 4    
    push eax 
    push img
    call task1_print
    add esp, 8
    jmp done
    
solve_task2:
    push img
    call bruteforce_singlebyte_xor  
    add esp, 4
    push eax 
    push img
    call xor_encryption
    add esp, 8
    jmp done
    
solve_task3:
    mov eax, [ebp + 12]
    push dword[eax + 16]
    push dword[eax + 12]
    push img
    call morse_encrypt
    add esp, 12
    jmp done
    
solve_task4:
    mov eax, [ebp + 12]
    push dword[eax + 16]
    push dword[eax + 12]
    push img
    call lsb_encode
    add esp, 12
    jmp done
    
solve_task5:
    mov eax, [ebp + 12]
    push dword[eax + 12]
    push img
    call lsb_decode
    add esp, 8
    jmp done
    
solve_task6:
    push img
    call blur 
    add esp, 4    
    jmp done

    ; Free the memory allocated for the image.
done:
    push DWORD[img]
    call free_image
    add esp, 4

    ; Epilogue
    ; Do not modify!
    xor eax, eax
    leave
    ret
    
