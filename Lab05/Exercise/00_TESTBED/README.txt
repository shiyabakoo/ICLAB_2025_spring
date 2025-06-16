Run flow:

	1. Put all file in 00_TEXTBED
	2. Run gen.py to generate input.txt
		cmd: python3 gen.py
	3. Run solve.py to generate output_int.txt output_float.txt
		cmd: python3 solve.py
	4. Then you can us PATTERN.v to debug

Notice:

	Default PATTERN_NUM is 100
	If you want to adjust please open gen.py in line16 find PATTERN_NUM and adjust it.

Warning:

	Unrecommand adjust PATTERN_NUM > 100, because when you genrate the output answer will spend a lot of time.