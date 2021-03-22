# Low Level I/O Procedures

**Low Level I/O Procedures** is a program written in assembly to validate a list of signed integers (small enough to fit in a 32-bit register) entered by the user, calculate and display the sum, and calculate and display the average. It utilizes string primitives and macro definitions to emulate functionality of the Irvine Library's `ReadInt` and `WriteInt` instructions.

User inputs are read as strings, then parsed character-by-character, converted, and stored as their integer equivalent in memory. To display the list of integers and calculations performed on the data set, the integers are then converted back to strings and printed to the console output.

![image](https://user-images.githubusercontent.com/69094063/111959833-f68f4000-8abc-11eb-82f6-66a751ffab92.png)
