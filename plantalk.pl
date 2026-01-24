# plantalk.pl

# 【免責事項】
# 
# このスクリプトに含まれるプログラムおよび関連情報（以下「本プログラム等」）は、無償で提供されています。本プログラム等のご利用に際しては、下記の事項を必ずご確認いただき、ご同意の上でご利用ください。
# 
# 1.  **無保証**:
#     作者（または運営者）は、本プログラム等の動作、性能、正確性、完全性、特定の目的への適合性、安全性について、いかなる保証も行いません。
# 2.  **自己責任**:
#     本プログラム等の利用は、利用者自身の責任において行ってください。本プログラム等の利用、または利用できなかったことにより利用者に生じた直接的、間接的ないかなる損害（データの消失、機器の故障、業務の中断などを含むがこれらに限らないあらゆる損害）に対しても、作者は一切の責任を負いません。
# 3.  **内容の変更等**:
#     作者は、利用者に事前の通知をすることなく、本プログラム等の内容の全部または一部を変更、追加、または提供を中止する場合があります。これにより利用者に生じた損害についても、作者は責任を負いません。
# 4.  **著作権**:
#     本プログラム等に関する著作権およびその他の権利は、作者または正当な権利者に帰属します。
# 
# 上記内容に同意できない場合は、本プログラム等の利用をお控えください。
# 本プログラム等を利用した場合、上記内容に同意したとみなします。
#

# usage: perl plantalk.pl --annotation [xxx.emapper.annotations] --geneseq [trinity.fasta] --expression [salmon_result.txt] --geneontology [go-basic.obo] --experimentals xxx xxx xxx xxx --controls yyy yyy yyy
# example: perl plantalk.pl --annotation ./eggNOG/test.emapper.annotations --geneseq ./trinity/trinity.fasta --expression ../salmon/salmon_result.txt --geneontology go-basic.obo --experimentals 5 6 7 --controls none1 none2 solvent1 solvent3 stimulated_0day_02 stimulated_4day_01


# 引数を受け取る
my @argument;
my $argvs;
foreach my $n (@ARGV){
	$argument[$argvs] = $n;
	$argvs++;
}

my $annotation_file;	# 必要なファイル名。正しいかどうかチェックする
my $gene_seq_file;
my $protein_seq_file;
my $expression_file;
my $ontology_file;

my $output_dir = 'plantalk_result';		# 出力先ディレクトリ

my $max_genes=0.03;		# 0.03の場合、全遺伝子の3%以上に存在するGOはカット
my $min_genes=4;		# 4 の場合、３個以下の遺伝子にしか含まれないGOはカット

my @experimental_argument;	# 実験区のサンプル
my @experimental_sample;
my @experimental_sample_name;
my $experimental_samples=0;
my %experimental_sample_num;
my $confirmed_experimental_samples=0; # 実際に存在するか確認する

my @control_argument;		# 対照区のサンプル
my @control_sample;
my @control_sample_name;
my $control_samples=0;
my %control_sample_num;
my $confirmed_control_samples=0; # 実際に存在するか確認する

my @argument_error;		# エラーメッセージ
my $argument_errors=0;

my @confirm_argument;	# 判定結果。TRUE/undef
my @confirm_arg_name=(	'--annotation',		# 必須な引数のリスト
						'--geneseq',
						'--proteinseq',
						'--expression',
						'--geneontology',
						'--experimentals',
						'--controls');		# 必須なのはここまで

my $fatal_error_flag = undef;
my $show_sample_name_flag = undef;
my $help_flag = undef;

print "\n";
for(my $i=0;$i<$argvs;$i++){		# ユーザーから渡された引数を解釈する
	if($argument[$i] =~ /\-/){
		if($argument[$i] eq '--annotation'){
			$annotation_file = $argument[$i+1];
			$confirm_argument[0]=TRUE;
			$i++;
			next;
		}
		if($argument[$i] eq '--geneseq'){
			$gene_seq_file = $argument[$i+1];
			$confirm_argument[1]=TRUE;
			$i++;
			next;
		}
		if($argument[$i] eq '--proteinseq'){
			$protein_seq_file = $argument[$i+1];
			$confirm_argument[2]=TRUE;
			$i++;
			next;
		}
		if($argument[$i] eq '--expression'){
			$expression_file = $argument[$i+1];
			$confirm_argument[3]=TRUE;
			$i++;
			next;
		}
		if($argument[$i] eq '--geneontology'){
			$ontology_file = $argument[$i+1];
			$confirm_argument[4]=TRUE;
			$i++;
			next;
		}
		if($argument[$i] eq '--experimentals'){
			$confirm_argument[5]=TRUE;
			$i++;
			while(TRUE){
				if($argument[$i] =~ /\-/){
					$i--;
					last;
				}
				if($i >= $argvs){
					last;
				}
				$experimental_argument[$experimental_samples]=$argument[$i];
				$experimental_samples++;
				$i++;
			}
			next;
		}
		if($argument[$i] eq '--controls'){
			$confirm_argument[6]=TRUE;
			$i++;
			while(TRUE){
				if($argument[$i] =~ /\-/){
					$i--;
					last;
				}
				if($i >= $argvs){
					last;
				}
				$control_argument[$control_samples]=$argument[$i];
				$control_samples++;
				$i++;
			}
			next;
		}
		if($argument[$i] eq '--output'){
			$output_dir = $argument[$i+1];
			$confirm_argument[7]=TRUE;
			$i++;
			next;
		}
		if($argument[$i] eq '--max_genes'){
			$max_genes = $argument[$i+1];
			$confirm_argument[8]=TRUE;
			$i++;
			next;
		}
		if($argument[$i] eq '--min_genes'){
			$min_genes = $argument[$i+1];
			$confirm_argument[9]=TRUE;
			$i++;
			next;
		}

		if($argument[$i] eq '-show_sample_names'){
			$confirm_argument[10]=TRUE;
			$show_sample_name_flag = TRUE;
			next;
		}
		if($argument[$i] eq '-help'){
			$confirm_argument[11]=TRUE;
			$help_flag = TRUE;
			next;
		}
	}
	# ここに来たら引数の文法が違っている可能性が高い
	print 'argument "'.$argument[$i].'" is invalid.'."\n";
	print 'argument syntax maybe wrong.'."\n";
	$fatal_error_flag = TRUE;
}

# 引数で渡された情報が正しいかチェックする 

if(-f $annotation_file){		# empperの結果ファイル。２行目にemapperと書かれていればたぶんOK
	open IN, $annotation_file;
	my $line1 = <IN>;
	my $line2 = <IN>;
	if($line2 =~ /emapper/){}else{
		$fatal_error_flag =TRUE;
		print 'ERROR: unknown format of annotation file: '. $annotation_file."\n";
	}
	close IN;
}else{
	$fatal_error_flag =TRUE;
	print 'ERROR: annotation result file NOT found: '.  $annotation_file."\n";
}

if(-f $gene_seq_file){			# trinityの結果ファイル。最初の文字が > なら多分fasta
	open IN, $gene_seq_file;
	my $line=<IN>;
	if($line =~ /^\>/){}else{
		$fatal_error_flag =TRUE;
		print 'ERROR: unknown format in DNA sequence file: '. $gene_seq_file."\n";
	}
}else{
	$fatal_error_flag =TRUE;
	print 'ERROR: gene & sequence file NOT found: '.$gene_seq_file."\n";
}

if(-f $protein_seq_file){		# transdecoder の結果ファイル。これも > だけチェックする
	open IN, $protein_seq_file;
	my $line=<IN>;
	if($line =~ /^\>/){}else{
		$fatal_error_flag =TRUE;
		print 'ERROR: unknown format in protein sequence file: '.$protein_seq_file."\n";
	}
}else{
	$fatal_error_flag =TRUE;
	print 'ERROR: protein & sequence file NOT found: '.$protein_seq_file."\n";
}

if(-f $expression_file){}else{		# salmon の結果ファイル。あとで詳しく見るのでここでは存在だけチェック
	$fatal_error_flag =TRUE;
	print 'ERROR: expression analysis file NOT found: '.$expression_file."\n";
}

if(-f $ontology_file){				# GO の辞書ファイル。go-basic.obo は最初の行に format-version: とある
	open IN, $ontology_file;
	my $line=<IN>;
	if($line =~ /format\-version\:/){}else{
		$fatal_error_flag =TRUE;
		print 'ERROR: unknown format of ontology reference: '. $ontology_file."\n";
	}
	close IN;
}else{
	$fatal_error_flag =TRUE;
	print 'ERROR: ontology reference file NOT found: '. $ontology_file."\n";
}

if($output_dir =~ /\/$/){		# 出力先ディレクトリ指定。最後に/が付いていたら外す。
	$output_dir = substr($output_dir,0,-1);
}

if(mkdir $output_dir){
	print 'output directory prepared: '.$output_dir."\n";	
}else{
	print 'ERROR: mkdir failed. maybe permittion denied?'."\n";
}



if($max_genes =~ /^[0-9]+\.[0-9]+$/){
	if($max_genes > 0.1){
		$max_genes=0.1;
		print '--max_genes over 0.1. set to maxmum value: '.$max_genes."\n";
	}
}else{
	$max_genes = 0.03;
	print '--max_genes argument looks invalid. set to default value: '.$max_genes."\n";
}
if($min_genes =~ /^[0-9]+$/){
	if($min_genes < 3){
		$min_genes=3;
		print '--min_genes less than 3. set to minimum value: '.$min_genes."\n";
	}
}else{
	$min_genes = 4;
	print '--min_genes argument looks invalid. set to default value: '.$min_genes."\n";
}

print "\n";
print 'provided arguments required to work:'."\n";
print 'annotation result:   '.$annotation_file."\n";
print 'geneID & sequence:   '.$gene_seq_file."\n";
print 'protein & sequence:  '.$protein_seq_file."\n";
print 'expression analysis: '.$expression_file."\n";
print 'gene ontology ref:   '.$ontology_file."\n";

print 'experimentals: ';
for(my $i=0;$i<$experimental_samples;$i++){
	print $experimental_argument[$i].' ';
}
print "\n";
print 'controls: ';
for(my $i=0;$i<$control_samples;$i++){
	print $control_argument[$i].' ';
}
print "\n\n";

my %sample_num;		# salmon の中でみつけたサンプルの番号
my @sample_name;	# salmon の中でみつけたサンプルの名前
my $samples=0;		# salmon の中にあったサンプルの数
if(-f $expression_file){
	print 'expression analysis file found: '.$expression_file."\n";
	open IN, $expression_file;
	my $first = <IN>;
	my @s = split(/\t/,$first);
	foreach my $st (@s){
		$sample_num{$st} = $samples;
		$sample_name[$samples] = $st;
		$samples++;
	}
	close IN;
	print $samples-1;
	print ' samples found'."\n";

	# experimental と control のサンプル指定からサンプル番号とサンプル名を探す
	for(my $i=0;$i<$experimental_samples;$i++){
		if($experimental_argument[$i] =~ /^[0-9]+$/){
			$experimental_sample_name[$i] = $s[$experimental_argument[$i]];
			$experimental_sample[$i] = $experimental_argument[$i];
		}else{
			$experimental_sample_name[$i] = $experimental_argument[$i];
			$experimental_sample[$i] = $sample_num{$experimental_argument[$i]};
		}
		# $experimental_sample_num{$experimental_sample_name[$i]} = $experimental_sample[$i];
	}
	for(my $i=0;$i<$control_samples;$i++){
		if($control_argument[$i] =~ /^[0-9]+$/){
			$control_sample_name[$i] = $s[$control_argument[$i]];
			$control_sample[$i] = $control_argument[$i];
		}else{
			$control_sample_name[$i] = $control_argument[$i];
			$control_sample[$i] = $sample_num{$control_argument[$i]};
		}
		# $control_sample_num{$control_sample_name[$i]} = $control_sample[$i];
	}
}else{
	$fatal_error_flag =TRUE;
	print 'expression analysis file: NOT found'."\n";
	$argument_error[$argument_errors]='expression analysis file NOT found: '.$expression_file;
	$argument_errors++;
}

print 'experimental samples:'."\n";
for(my $i=0;$i<$experimental_samples;$i++){
	if(defined($experimental_sample[$i]) && defined($experimental_sample_name[$i])){
		print 'OK'."\t";
	}else{
		print 'NG'."\t";
		$show_sample_name_flag = TRUE;
		$argument_error[$argument_errors]='experimental sample "'.$experimental_argument[$i].'" is NOT found';
		$argument_errors++;
	}
	print $experimental_sample[$i]."\t";
	print $experimental_sample_name[$i]."\t\t";
	print '(arg: '.$experimental_argument[$i].')'."\n";
}
print "\n";
print 'control samples:'."\n";
for(my $i=0;$i<$control_samples;$i++){
	if(defined($control_sample[$i]) && defined($control_sample_name[$i])){
		print 'OK'."\t";
	}else{
		print 'NG'."\t";
		$show_sample_name_flag = TRUE;
		$argument_error[$argument_errors]='control experiment "'.$control_argument[$i].'" is NOT found';
		$argument_errors++;

	}
	print $control_sample[$i]."\t";
	print $control_sample_name[$i]."\t\t";
	print '(arg: '.$control_argument[$i].')'."\n";
}
print "\n";

# サンプルが引数通りに存在していない場合の処理が必要だった
for(my $i=0;$i<$experimental_samples;$i++){
	if(defined($experimental_sample[$i]) && defined($experimental_sample_name[$i])){
		$experimental_sample[$confirmed_experimental_samples] = $experimental_sample[$i];
		$experimental_sample_name[$confirmed_experimental_samples] = $experimental_sample_name[$i];
		$experimental_sample_num{$experimental_sample_name[$i]} = $experimental_sample[$i];
		$confirmed_experimental_samples++;
	}
}
for(my $i=0;$i<$control_samples;$i++){
	if(defined($control_sample[$i]) && defined($control_sample_name[$i])){
		$control_sample[$confirmed_control_samples] = $control_sample[$i];
		$control_sample_name[$confirmed_control_samples] = $control_sample_name[$i];
		$control_sample_num{$control_sample_name[$i]} = $control_sample[$i];
		$confirmed_control_samples++;
	}
}
if($confirmed_experimental_samples>0){
	print $confirmed_experimental_samples.' of '.$experimental_samples.' experimental samples found'."\n";
}else{
	print 'No experimental samples found'."\n";
	$fatal_error_flag = TRUE;
}
if($confirmed_control_samples>0){
	print $confirmed_control_samples.' of '.$control_samples.' contol samples found'."\n";
}else{
	print 'No control samples found'."\n";
	$fatal_error_flag = TRUE;
}

# 引数のエラーについてのメッセージを表示
for(my $i=0;$i<6;$i++){		# ６番以降はoptional
	if($confirm_argument[$i]){}else{
		print 'ERROR: missing required argument "'.$confirm_arg_name[$i].'"'."\n";
	}
}
for(my $i=0;$i<$argument_errors;$i++){
	print $argument_error[$i]."\n";
}

# サンプル番号とサンプル名を表示
if($show_sample_name_flag){
	if(-f $expression_file){
		print "\n".'samples found in '.$expression_file.':'."\n\n";
		print 'number'."\t"."sample name"."\n";
		for(my $i=1;$i<$samples;$i++){
			print $i."\t".$sample_name[$i]."\t";
			if($experimental_sample_num{$sample_name[$i]} == $i){print 'experimental';}
			if($control_sample_num{$sample_name[$i]} == $i){print 'control';}
			print "\n";
		}
		print "\n";
	}else{
		print 'expression analysis file NOT found: '.$expression_file."\n";	
		print 'please provide correct path and file name.'."\n";
	}
}

# 実行不能な場合のエラーメッセージを表示
if($fatal_error_flag){
	print "\n".'Error(s) occurred, impossible to work'."\n\n";
	$help_flag=TRUE;
}

# ヘルプを表示
if($help_flag){
	print '#####################'."\n";
	print '# plantalk ver0.0.1 #'."\n";
	print '#####################'."\n\n";
	print 'Usage:'."\n";
	print 'perl plantalk.pl [arguments]'."\n\n";
	print 'required arguments:'."\n";
	print "\n".'--annotation [file path to eggNOG mapper result]'."\n";
	print 'emapper output with ".annotation" extension; ex) ./eggNOG/xxx.emapper.annotations'."\n";
	print "\n".'--geneseq [file path to trinity result]'."\n";
	print 'DNA sequence file written in fasta format; ex) ./trinity/Trinity.fasta'."\n";
	print "\n".'--proteinseq [file path to transdecoder result]'."\n";
	print 'transdecoder output with ".transdecoder.pep" extention; ex) ./transdecoder/Trinity.fasta.transdecoder.pep'."\n";
	print "\n".'--expression [file path to salmon result]'."\n";
	print 'salmon merge output; ex) ./salmon/salmon_result.txt'."\n";
	print "\n".'--geneontology [file path to GO reference "go-basic.obo"]'."\n";
	print 'gene ontology reference data provided by the official GO consortium; ex) go_basic.obo'."\n";
	print "\n".'--experimental [numbers and/or sample names, for experimentals]'."\n";
	print '--control [numbers and/or sample names, for controls]'."\n";
	print 'sample names and/or numbers which you assigned in the "salmon merge" process;'."\n";
	print ' to show the applicable nums and words, set -show_sample_names option'."\n";
	print "\n";
	print 'optional arguments:'."\n";
	print "\n".'--output [directory]'."\n";
	print 'output directory name; if nothing provided, default name "plantalk_result" is used'."\n";
	print "\n".'--max_genes [numeric, float, less than 1.00]'."\n";
	print 'to set maximum frequency of GOs in genes, excess GOs are excluded. default: 0.03'."\n";
	print "\n".'--min_genes [numeric, int, more than 2]'."\n";
	print 'to set minimum frequency of GOs in genes, too unique GOs are excluded. default: 4'."\n";
	print "\n".'-show_sample_names '."\n";
	print 'force to show sample names applicable in --experimental and --control arguments'."\n";
	print "\n".'-help'."\n";
	print 'force to show this message.'."\n";
	print "\n";
	exit();
}

###########
# 計算開始 #
###########

# GO-ID と GO-Term の対応表を作る
{
	print '*** Re-formatting GO reference ***'."\n";

	my $count=0;		# 行数を数える
	open IN, $ontology_file;
	while(my $line=<IN>){		# 冒頭を飛ばす
		$count++;
		if($line=~/\[Term\]/){last;}
	}

	# 探索開始
	my @go_id;		# $go_id[flag][gos]
	my @go_term;	# $go_term[flag][gos]
	my @gos;		# $gos[flag]
	$gos[0]=0;	# biological process の数
	$gos[1]=0;	# molecular function の数
	$gos[2]=0;	# cellular component の数

	my @go_id_non;	# ３カテゴリーを分けない
	my @go_term_non;
	my $gos_total=0;	# id: の数
	my $other=0;		# ３class に含まれないGOの数
	while(my $line=<IN>){
		# 次のIDを探す
		if(substr($line,0,3) eq 'id:'){
			$line =~ s/\n|\r|\n\r//g; 
			my @s = split(/ /,$line);
			if($s[0] ne 'id:'){
				print 'error: wrong format'."\n";
				exit();
			}	

			# 次の行にnameがあるはず
			my $line2=<IN>;
			$line2 =~ s/\n|\r|\n\r//g; 
			my @ss = split(/ /,$line2);
			if($ss[0] ne 'name:'){
				print 'error: wrong format'."\n";
				exit();
			}
			my $name = substr($line2,6);	# name: xxxx なので６文字めから

			#次の行にnamespaceがあるはず
			my $line3=<IN>;
			my $flag=3;
			if($line3=~/biological/){$flag=0;}
			if($line3=~/molecular/){$flag=1;}
			if($line3=~/cellular/){$flag=2;}
			my @sss = split(/ /,$line3);
			if($sss[0] ne 'namespace:'){
				print 'error: wrong format'."\n";
				exit();
			}

			#データを登録
			if($flag<3){
				$go_id[$flag][$gos[$flag]] = $s[1];
				$go_term[$flag][$gos[$flag]] = $name;
				$gos[$flag]++;
			}else{
				# ３クラス以外は除外する。５個しかなかったしOK
				$other++;
			}
			#クラス分け関係ないリストも作ろう
			$go_id_non[$gos_total] = $s[1];
			$go_term_non[$gos_total] = $name;
			$gos_total++;

			$count=$count+2;
		}
		$count++;
	}
	close IN;

	#レポート
	print $count." lines\n";
	print $gos_total." GOs\n";
	print 'BiologicalProcess'."\t".$gos[0]."\n";
	print 'MolecularFunction'."\t".$gos[1]."\n";
	print 'CellularComponent'."\t".$gos[2]."\n";
	print 'other'."\t".$other."\n\n\n";

	#出力
	open OUT, '>'.$output_dir.'/IDtermRef_Bio.txt';
	for(my $i=0;$i<$gos[0];$i++){
		print OUT $go_id[0][$i]."\t".$go_term[0][$i]."\n";
	}
	close OUT;
	open OUT, '>'.$output_dir.'/IDtermRef_Mol.txt';
	for(my $i=0;$i<$gos[1];$i++){
		print OUT $go_id[1][$i]."\t".$go_term[1][$i]."\n";
	}
	close OUT;
	open OUT, '>'.$output_dir.'/IDtermRef_Cel.txt';
	for(my $i=0;$i<$gos[2];$i++){
		print OUT $go_id[2][$i]."\t".$go_term[2][$i]."\n";
	}
	close OUT;
	open OUT, '>'.$output_dir.'/IDtermRef.txt';
	for(my $i=0;$i<$gos_total;$i++){
		print OUT $go_id_non[$i]."\t".$go_term_non[$i]."\n";
	}
	close OUT;
}

# emapper の出力と GOのref から GO-term を追加して整理したデータを出力する
{
	print '*** Organizing annotation result ***'."\n";

	my $threshold = $max_genes;	# contig全体のこれ%以上に存在するGOは多すぎ扱い
	my %exgo;				# GO_IDを入れると登場回数を返すハッシュを作る
	my $contigs_with_GO=0;	# GOつきのcontigの数を数える
	my $contigs=0;

	# まず多すぎるGOを無視するためのthresholdを決める
	open IN, $annotation_file;
	while(my $line=<IN>){	# 冒頭を飛ばす
		if($line=~/query/){last}
	}
	while(my $line=<IN>){
		if($line =~ /queries scanned/){last;}	#フッターの目印。ここで終了
		my @s=split(/\t/,$line);
		my $go=$s[9];	# GOの列は９番目っぽい
		if(length($go)>8){$contigs_with_GO++;}	# GO付いてるcontigの数を数える
		my @ss=split(/\,/,$go);
		foreach my $id (@ss){$exgo{$id}++;}		# GOなしを意味する '-' も含む
		$contigs++;
	}
	close IN;
	my $lim = $contigs_with_GO * $threshold;

	print $contigs_with_GO.' / '.$contigs.' contigs had GO assigned'."\n";
	print int($lim);
	print ' set as limit of excess assigned GOs to be excluded'."\n\n";


	# 対応表をハッシュにロードする。多すぎるGOは見なかったことにする

	my %ref_bp;		# Biological Process
	my $exgo_bps=0;
	my $total_bps=0;
	open IN, $output_dir.'/IDtermRef_Bio.txt';
	print 'Biological Process'."\n";
	while(my $line=<IN>){
		$line =~ s/\n|\r|\r\n//g;
		my @s=split(/\t/,$line);
		if($exgo{$s[0]}<$lim){
			$ref_bp{$s[0]}=$s[1];
		}else{
#			print $exgo{$s[0]}."\t".$line."\n";
			$exgo_bps++;
		}
		$total_bps++;
	}
	close IN;
	print $exgo_bps.'/'.$total_bps."\n\n";

	my %ref_mf;		# Molecular Function
	my $exgo_mfs=0;
	my $total_mfs=0;

	open IN, $output_dir.'/IDtermRef_Mol.txt';
	print 'Molecular Function'."\n";
	while(my $line=<IN>){
		$line =~ s/\n|\r|\r\n//g;
		my @s=split(/\t/,$line);
		if($exgo{$s[0]}<$lim){
			$ref_mf{$s[0]}=$s[1];
		}else{
#			print $exgo{$s[0]}."\t".$line."\n";
			$exgo_mfs++;
		}
		$total_mfs++;
	}
	close IN;
	print $exgo_mfs.'/'.$total_mfs."\n\n";

	my %ref_cc;		# Cellular Component
	my $exgo_ccs=0;
	my $total_ccs=0;

	open IN, $output_dir.'/IDtermRef_Cel.txt';
	print 'Cellular Component'."\n";
	while(my $line=<IN>){
		$line =~ s/\n|\r|\r\n//g;
		my @s=split(/\t/,$line);
		if($exgo{$s[0]}<$lim){
			$ref_cc{$s[0]}=$s[1];
		}else{
#			print $exgo{$s[0]}."\t".$line."\n";
			$exgo_ccs++;
		}
		$total_ccs++;
	}
	close IN;
	print $exgo_ccs.'/'.$total_ccs."\n\n";


	# eggNOGの結果を順次見てGOにTermを当てて保存

	open IN, $annotation_file;
	# 冒頭を飛ばす
	while(my $line=<IN>){
		if($line=~/query/){last}
	}

	# contigのGO ID から GO term を割り当てる
	my @contig;		# contig名。.p1は要らない
	my @annotation;	# アノテーションでヒットしたエントリのID。重複の識別に使う
	my @go_bp;		# termつきのGO。BioProc
	my @go_mf;		# MolFunc
	my @go_cc;		# CelComp
	my $c=0;
	my $no_gos=0;
	while(my $line=<IN>){
		if($line =~ /queries scanned/){last;}	#フッター要らん行があったので飛ばす

		# 最初の列は contig ID。タンパク質の番号は.p2だったりもする注意
		my @s=split(/\t/,$line);
		$contig[$c]=substr($s[0],0,-3);		# .p1 とかのタンパク質の番号は不要
		$contig[$c] =~ s/\.$//;				# .p10 以上だと４文字なので'.'が残っちゃう場合に対応してみたが引っかからず

		$annotation[$c]=$s[1];			# アノテーションのときヒットしたエントリID

		# GOの列は９番目っぽい
		my $go=$s[9];
		my @ss=split(/\,/,$go);		# ここはGO-IDなのでコンマは無い。termになるとコンマがデータ中にある。

		# 新しいGOの列を別の区切り文字列で作る。セミコロンにしよう。カンマと空白はダメ。タブもダメ。
		foreach my $id (@ss){
			if(exists($ref_bp{$id})){
				my $term = $ref_bp{$id};
				$go_bp[$c] = $go_bp[$c].';'.$id.'_'.$term;	# 最初にセミコロン一個入っちゃった
			}
			if(exists($ref_mf{$id})){
				my $term = $ref_mf{$id};
				$go_mf[$c] = $go_mf[$c].';'.$id.'_'.$term;
			}
			if(exists($ref_cc{$id})){
				my $term = $ref_cc{$id};
				$go_cc[$c] = $go_cc[$c].';'.$id.'_'.$term;
			}
		}
		$go_bp[$c] =~ s/^\;//g;	# 最初のセミコロンを削除
		$go_mf[$c] =~ s/^\;//g;
		$go_cc[$c] =~ s/^\;//g;

		# GOついてないannotationがあるかチェック。eggNOGmapperのせい。
		my $go_ln = $go_bp[$c].$go_mf[$c].$go_cc[$c];
		if($go_ln=~ /GO\:/){}else{$no_gos++;}

		$c++;
	}
	close IN;

	#レポート
	print 'total contigs:  '.$c."\n";
	print 'no GO assigned: '.$no_gos."\n";

	# 出力。contig \t BP \t MF \t CC \n の順
	open OUT, '>'.$output_dir.'/gene_annotation_GOs.txt';
		for(my $i=0;$i<$c;$i++){
			print OUT $contig[$i]."\t".$annotation[$i]."\t".$go_bp[$i]."\t".$go_mf[$i]."\t".$go_cc[$i]."\n";
		}
	close OUT;
}
print "\n\n";

# 遺伝子の塩基配列データとアノテーション結果から重複を排除したものを出力
{
	print '*** Extracting effective data ***'."\n";

	# まずTrinity.fastaのcDNAデータをロード。
	# ソートされていないので.pepやGOとは順番が違うハッシュを使おう
	my %trinity_len;
	my %trinity_seq;
	my $trinitys=0;
	open IN, $gene_seq_file;
	while(my $line=<IN>){
			if($line =~ /^\>/){
				my @s = split(/ /,$line);
				my $trinity_id =substr($s[0],1);
				$trinity_len{$trinity_id}=substr($s[1],4);
				while(my $seq=<IN>){		# 改行のあるfastaに対応しておく
					$seq =~ s/\r|\n|\r\n//g;
					$trinity_seq{$trinity_id}=$trinity_seq{$trinity_id}.$seq;
					if($trinity_len{$trinity_id} == length($trinity_seq{$trinity_id})){last;}
					if(length($trinity_seq{$trinity_id})>100000){	# エラーはないはずだが一応安全弁をセットしておく
						print 'too long gene: '.length($trinity_seq{$trinity_id}).' at #'.$trinitys."\n";
						exit();}
				}
			}else{
				print 'error in fasta format'."\n";
				exit();
			}
			$trinitys++;
	}
	close IN;

	print $trinitys.' contigs loaded from fasta file'."\n";

	# 次にGO割当データをロード。これも数と順番が変わっているのでハッシュで
	my %anno_an;
	my %anno_bp;
	my %anno_mf;
	my %anno_cc;
	my $annos=0;
	open IN, $output_dir.'/gene_annotation_GOs.txt';
	while(my $line=<IN>){
		$line =~ s/\r|\n|\r\n//;
		my @s = split(/\t/,$line);
		$anno_an{$s[0]}=$s[1];
		$anno_bp{$s[0]}=$s[2];
		$anno_mf{$s[0]}=$s[3];
		$anno_cc{$s[0]}=$s[4];
		$annos++;
	}
	close IN;
	print $annos.' lines loaded from GO assigned data'."\n";

	open IN, $protein_seq_file;
	my @cluster;		# クラスター内における番号からcontig名の配列を引き出すための配列
	my @cluster_len;	# クラスター内のlenを比べる計算用
	my @cluster_group;	# クラスター内におけるグループ番号
	my $clusters=0;
	my $prev_cluster;	# 一つ前のクラスター名 M14d12345_c0_g1 まで
	my $contigs=0;
	my @result_id;		# 選抜されたcontigIDのリスト
	my $results=0;		# 選抜されたcontigの数
	while(my $line=<IN>){
		if($line =~ /^\>/){
			# まずコンティグ名とタンパク質長のデータを抽出しクラスター名を作る
			my @s=split(/ /,$line);
			my $contig_id = substr($s[0],1,-3);	# 頭の>と.p1 を取る。.p10以上は存在しなければこれでOK
			$contig_id =~ s/\.$//;				# .p10 以上だと４文字なので'.'が残っちゃう場合に対応してみたが引っかからず
			my $contig_len= substr($s[5],4);		# len:xxxx の　xxxx だけ抽出する。
			my $present_cluster = substr($contig_id,0,-3);	# 後ろ３文字削る '_i2'とか
			$present_cluster =~ s/\_$//;	# i12等i２桁の場合は３文字だと_が残る。２桁ある場合は削る
			$contigs++;

			# クラスター内だったらクラスターデータとして保存
			if($prev_cluster eq $present_cluster){
				$cluster[$clusters]=$contig_id;					# コンティグIDを登録
				$cluster_len[$clusters]=$contig_len;			# aa配列長を登録
				$clusters++;

			# 次のクラスターのデータに来たら前のクラスターを評価
			}else{

				# まずアノテーションをチェックする。ないか、１種類か、２種類以上あるかをチェック
				
				my @annotation;
				my $annotations=0;	# アノテーションの種類を数える
				my @cluster_skip;	# アノテーションが無い場合はスキップするのでリストを作る
				my @group;			# contigIDの２次元配列。アノテーションが２種類以上の場合に使う
				my @groups;			# ２次元目のメンバー数を表す１次元配列
				for(my $i=0;$i<$clusters;$i++){
					if($anno_an{$cluster[$i]} eq ''){	# まずアノテーションない場合はスキップリスト入り
						$cluster_skip[$i]=0;	# 0 はアノテーションなしのcontig
						$cluster_group[$i]=(-1);
					}else{
						$cluster_skip[$i]=1;	# 1 ならアノテーションありのcontig
					
						my $judge=1;	# アノテーションが２種類以上あるか調べる
						for(my $j=0;$j<$annotations;$j++){
							if($anno_an{$cluster[$i]} eq $annotation[$j]){
								$group[$j][$groups[$j]]=$i;	#既存のアノテに一致したら記録
								$groups[$j]++;
								$cluster_group[$i]=$j;
								$judge=0;
								last;
							}
						}
						if($judge==1){	# 新規アノテーションを発見した
							$group[$annotations][0] = $i;
							$groups[$annotations] = 1;
							$annotation[$annotations] = $anno_an{$cluster[$i]};
							$cluster_group[$i]=$annotations;
							$annotations++;
						}
					}
				}


				# アノテーションが１種類の場合
				if($annotations==1){
					my @candidate;	# タンパク質長が最長のものを選抜
					my $candidates=0;

					my $max_len=0;	# クラスター内で一番長いやつを探す（複数ありうる）
					for(my $i=0;$i<$clusters;$i++){
						if($cluster_skip[$i]==1){	# アノテーションのないcontigはスキップ
						if($max_len < $cluster_len[$i]){
							$max_len = $cluster_len[$i];
						}}
					}
					for(my $i=0;$i<$clusters;$i++){
						if($cluster_skip[$i]==1){	# アノテーションのないcontigはスキップ
						if($max_len == $cluster_len[$i]){
							$candidate[$candidates]=$cluster[$i];
							$candidates++;
						}}
					}
					# 最長ORFを持つものの中でcDNA長が最も短いものをひとつ選択
					my $min_len=999999;
					my $result;
					for(my $i=0;$i<$candidates;$i++){
						my $x = $trinity_len{$candidate[$i]};	#必ずヒットするはず・・
						if($min_len>$x){
							$min_len=$x;
							$result=$candidate[$i];
						}
					}
					$result_id[$results] = $result;
					$results++;
				}
				# アノテーションがついてない場合（タンパク質の予測はあるやつ）
				if($annotations==0){
					my @candidate;	# タンパク質長が最長のものを選抜
					my $candidates=0;

					my $max_len=0;	# クラスター内で一番長いやつを探す（複数ありうる）
					for(my $i=0;$i<$clusters;$i++){
						if($max_len < $cluster_len[$i]){$max_len = $cluster_len[$i];}
					}
					for(my $i=0;$i<$clusters;$i++){
						if($max_len == $cluster_len[$i]){
							$candidate[$candidates]=$cluster[$i];
							$candidates++;
						}
					}
					# 最長ORFを持つものの中でcDNA長が最も短いものをひとつ選択
					my $min_len=999999;
					my $result;
					for(my $i=0;$i<$candidates;$i++){
						my $x = $trinity_len{$candidate[$i]};
						if($min_len>$x){
							$min_len=$x;
							$result=$candidate[$i];
						}
					}
					$result_id[$results] = $result;
					$results++;

				}	
				# アノテーションが複数ある場合はグループごとにひとつ選ぶ
				if($annotations>1){
					for(my $j=0;$j<$annotations;$j++){
						$max_len=0;		# クラスター内最長値のデータが使えないので新たに探索
						for(my $i=0;$i<$groups[$j];$i++){
							if($max_len<$cluster_len[$group[$j][$i]]){$max_len=$cluster_len[$group[$j][$i]];}
						}
						my @candidate;	# タンパク質長が最長のものが複数ある可能性があるので全部選抜
						my $candidates=0;
						for(my $i=0;$i<$groups[$j];$i++){
							if($max_len == $cluster_len[$group[$j][$i]]){
								$candidate[$candidates]=$cluster[$group[$j][$i]];
								$candidates++;
							}
						}
						# 最長ORFを持つものの中でcDNA長が最も短いものをひとつ選択
						my $min_len=999999;
						my $result;
						for(my $i=0;$i<$candidates;$i++){
							my $x = $trinity_len{$candidate[$i]};
							if($min_len>$x){
								$min_len=$x;
								$result=$candidate[$i];
							}
						}
						$result_id[$results] = $result;
						$results++;
					}
				}

				# 次のクラスターの初期値をセット
				if($prev_cluster eq ''){$results=0;}		# 最初の一行のエラーを補正しておく（力業ww
				$prev_cluster = $present_cluster;
				$cluster[0]=$contig_id;
				$cluster_len[0]=$contig_len;
				$clusters=1;

			}	
		}
	}
	close IN;

	print $contigs.' proteins from transdecoder.pep analyzed'."\n";

	# 塩基配列のデータ。salmon再解析用
	open OUT, '>'.$output_dir.'/effective_genes.fasta';
	for(my $i=0;$i<$results;$i++){
		print OUT '>'.$result_id[$i]."\n";
		print OUT $trinity_seq{$result_id[$i]}."\n";
	}
	close OUT;
	# アノテーションのデータ。解析続行用
	open OUT, '>'.$output_dir.'/effective_gene_annotation_GOs.txt';
	for(my $i=0;$i<$results;$i++){
		print OUT $result_id[$i]."\t";
		print OUT $anno_an{$result_id[$i]}."\t";
		print OUT $anno_bp{$result_id[$i]}."\t";
		print OUT $anno_mf{$result_id[$i]}."\t";
		print OUT $anno_cc{$result_id[$i]}."\n";
	}
	close OUT;

	print $results." contigs looks effective \n";
	print 'Recommended: re-analyze gene expression using "effective_genes.fasta" '."\n";
}
print "\n\n";

# さいご。GOごとに集計する。結果をexcelなどで開いて人力目視で意味重複するGOを取り除けば完成
{
	print '*** calculating GO expression foldchange  ***'."\n";
	# 発現量データをロードしてfoldchangeの対数を取っておく
	my %foldchange_log;		# 発現量比。対数にしておく。引数はcontigID
	my $genes=0;			# 遺伝子の数も数えておく
	my $max_expression=0;
	my $min_expression=1;

	# salmonの結果をロード。

#	my $minimum_gene_number = $min_genes;	# GO に含まれる遺伝子数の下限

	open IN, $expression_file;

	my $header = <IN>;	# 一行めはメタデータなので飛ばす
#	my @head_split = split(/\t/,$header);
#	my $number=0;	# 実験区の番号。これで指定する
#	foreach my $x (@head_split){
#		print $number."\t".$x."\n";
#		$number++;
#	}


	while(my $line=<IN>){
		my @s=split(/\t/,$line);

		my $treat=0;	# 実験区における遺伝子の発現量を足し算する
		for(my $i=0;$i<$confirmed_experimental_samples;$i++){
			$treat = $treat + $s[$experimental_sample[$i]];
			if($max_expression<$s[$experimental_sample[$i]]){$max_expression=$s[$experimental_sample[$i]];}
			if($s[$experimental_sample[$i]]>0){
			if($min_expression>$s[$experimental_sample[$i]]){$min_expression=$s[$experimental_sample[$i]];}}
		}
		$treat = $treat/$confirmed_experimental_samples;
		if($treat==0){$treat=0.000001;}	# ゼロだと割り算できないので。

		my $contr=0;	# 対照区における遺伝子の発現量を足し算する
		for(my $i=0;$i<$confirmed_control_samples;$i++){
			$contr = $contr + $s[$control_sample[$i]];
			if($max_expression<$s[$control_sample[$i]]){$max_expression=$s[$control_sample[$i]];}
			if($s[$control_sample[$i]]>0){
			if($min_expression>$s[$control_sample[$i]]){$min_expression=$s[$control_sample[$i]];}}
		}
		$contr = $contr/$confirmed_control_samples;
		if($contr==0){$contr=0.000001;}	# ゼロだと割り算できないので。

		# 実験区と対照区を割り算してから対数にする。これで遺伝子のlogFCになる
		$foldchange_log{$s[0]} = log($treat/$contr);
		$genes++;
	}
	close IN;
	print 'total genes: '.$genes."\n";
	print 'max expression: '.$max_expression."\n";
	print 'min expression: '.$min_expression."\n";

	# GOごとにfoldchangeを集計する
	my %GOterm_foldchange;	# ID を入れるとGOの発現量比が出る。対数にして足す
	my %GOterm_frequency;	# GO に属する遺伝子の数。あとで割り算する用	
	my @GOterm;		# ハッシュの呼び出しキーにするtermを返す。不要かもしれない
	my $GOterms=0;	# termの数を数える。不要かもしれない
	my $contigs=0;	# 遺伝子の総数も一応数えておく
	 
	open IN, $output_dir.'/effective_gene_annotation_GOs.txt';
	while(my $line=<IN>){
		$line =~ s/\r|\n|\r\n//g;
		my @s = split(/\t/,$line);
		my $contig_name = $s[0];
		my $contig_annotation = $s[1];
		my $contig_GO_bp = $s[2];		# Bioprocess に属する GO term だけ使う
		my $contig_GO_mf = $s[3];
		my $contig_GO_cc = $s[4];

		my @ss = split(/\;/,$contig_GO_bp);
		foreach my $term (@ss){						# log(FC)を足し算で足す（あとでnで割る）
			if(exists($GOterm_foldchange{$term})){
				$GOterm_foldchange{$term} += $foldchange_log{$contig_name};
				$GOterm_frequency{$term}++;
			}else{
				$GOterm_foldchange{$term} = $foldchange_log{$contig_name};
				$GOterm_frequency{$term}  = 1;
				$GOterm[$GOterms] = $term;
				$GOterms++;
			}
		}
		$contigs++;
	}

	close IN;

	print 'total contigs: '.$contigs."\n\n";;

	# 遺伝子の数で割り算してeの指数にすると相乗平均が出る
	for(my $i=0;$i<$GOterms;$i++){
		$GOterm_foldchange{$GOterm[$i]} /= $GOterm_frequency{$GOterm[$i]}; 	# これで log(FC)。式は複雑だが直感的
		$GOterm_foldchange{$GOterm[$i]} = exp(1) ** $GOterm_foldchange{$GOterm[$i]};	# これでFC。式は簡単だが倍率なので注意
	}

	my $max_foldchange=0;	# 最大値と最小値をチェック
	my $min_foldchange=1;
	my $pass=0;

	for(my $i=0;$i<$GOterms;$i++){
		my $value=$GOterm_foldchange{$GOterm[$i]};
		if($GOterm_frequency{$GOterm[$i]} >= $minimum_gene_number){
			if($max_foldchange<$value){$max_foldchange=$value;}
			if($min_foldchange>$value){$min_foldchange=$value;}
			$pass++;
		}
	}
	print 'max foldchange: '.$max_foldchange."\n";
	print 'min foldchange: '.$min_foldchange."\n";
	print 'GOs pass criteria >= '.$min_genes.' genes: '.$pass."\n";

	# GO_ID+term がハッシュのキーになっているので sort の keys で呼び出せる
	open OUT, '>'.$output_dir.'/GOfoldchange_sorted.txt';
	open LOG, '>'.$output_dir.'/GOlogFC_sorted.txt';
	for my $key (reverse sort{%GOterm_foldchange{$a} <=> %GOterm_foldchange{$b}} keys %GOterm_foldchange){
		my $name = $key;
		$name =~ s/^GO\:\d{7}\_//;		# GO-ID を消して GO-term だけを使う
		if($GOterm_frequency{$key} >= $min_genes){	# 遺伝子数が極端に少ないGOは外す
			print OUT $name."\t".$GOterm_foldchange{$key}."\t".$GOterm_frequency{$key}."\n";
			my $logfc = log($GOterm_foldchange{$key});
			print LOG $name."\t".$logfc."\t".$GOterm_frequency{$key}."\n";
		}
	}
	close LOG;
	close OUT;

	print "\n\n";
	print 'Please find result file "GOfoldchange_sorted.txt" in unit of foldchange.'."\n";
	print 'Please find result file "GOlogFC_sorted.txt" in unit of log(foldchange).'."\n\n";
	print 'Manual curation may be necessary before input the data into AI.'."\n";
	print 'Hint: redundant GOs share same numeric score, representative one is enough.'."\n";
	print 'Both of Top and Bottom 50 terms may be effective to see mean using AI.'."\n\n";
}

