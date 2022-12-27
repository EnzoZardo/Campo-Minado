Function init {
	# [Console]::WindowWidth = 60;
	# [Console]::WindowHeight = 31;
	$global:gridSize = 10;
	$global:gridRealSize = $gridSize + 2;
	$global:grid = [System.Collections.ArrayList]::New();
	$global:gridScreen = [System.Collections.ArrayList]::New();
	$global:primeiroClick = $true;
	$global:rodando = $true;
	$global:bandeiraSelected = $false;
	$global:bombProb = @("X", "X", "C", "C", "C", "C");
	$global:target = @(1, 1);
	$global:ui = (get-host).ui;
	$global:rui = $ui.rawui;
	$global:bandeiras = 10;
}

Function randint([Int] $min, [Int] $max) {
	return [Random]::New().Next($min, $max);
}

Function vaziosaoredor([Int] $x, [Int] $y) {
	$pVerificar = @(@(-1, -1), @(0, -1), @(1, -1),
					@(-1, 0), @(1, 0), 
					@(-1, 1), @(0, 1), @(1, 1));
	for ([Int] $i = 0; $i -lt $pVerificar.Count; $i++) {
		$gridTemp = $grid[$y + $pVerificar[$i][1]][$x + $pVerificar[$i][0]];
		if ($gridTemp -eq "0" -and $gridScreen[$y + $pVerificar[$i][1]][$x + $pVerificar[$i][0]] -ne "P") {
			$levaX = $x + $pVerificar[$i][0];
			$levaY = $y + $pVerificar[$i][1];
			click ($x + $pVerificar[$i][0]) ($y + $pVerificar[$i][1]);
			$grid[$levaY][$levaX] = ".";
			vaziosaoredor $levaX $levaY;
		} else {
			if ($gridTemp -ne "B" -and $gridTemp -ne "X" -and $gridTemp -ne "." -and $gridScreen[$y + $pVerificar[$i][1]][$x + $pVerificar[$i][0]] -ne "P") {
				click ($x + $pVerificar[$i][0]) ($y + $pVerificar[$i][1]);
			}
		}
	}
}

Function filtragrid {
	for ([Int] $y = 0; $y -lt $gridRealSize; $y++) {
		for ([Int] $x = 0; $x -lt $gridRealSize; $x++) {
			$grid[$y][$x] = verificabombas $x $y;
		}
	}
}

Function verificabombas([Int] $x, [Int] $y) {
	$pVerificar = @(@(-1, -1), @(0, -1), @(1, -1),
					@(-1, 0), @(1, 0), 
					@(-1, 1), @(0, 1), @(1, 1));
	$contBombas = 0;
	if ($grid[$y][$x] -eq "X" -or $grid[$y][$x] -eq "B") {
		return $grid[$y][$x];
	}
	for ([Int] $i = 0; $i -lt $pVerificar.Count; $i++) {
		if ($grid[$y + $pVerificar[$i][1]][$x + $pVerificar[$i][0]] -eq "X") {
			$contBombas++;
		}
	}
	return $contBombas;
}

Function populagrid {
	for ([Int] $y = 0; $y -lt $gridRealSize; $y++) {
		$grid.Add([System.Collections.ArrayList]::New());
		$gridScreen.Add([System.Collections.ArrayList]::New());
		for ([Int] $x = 0; $x -lt $gridRealSize; $x++) {
			if ($y -eq 0 -or $y -eq ($gridRealSize - 1) -or $x -eq 0 -or $x -eq ($gridRealSize - 1)) {
				$grid[$y].Add("B");
				$gridScreen[$y].Add("B");
			} else {
				$index = randint 0 ($bombProb.Count - 1);
				$grid[$y].Add($bombProb[$index]);
				$gridScreen[$y].Add("O");
			}
		}
	}
	cls;
}

Function gridtostring {
	foreach ($y in $grid) {
		$line = "";
		foreach ($x in $y) {
			$line += $x;
		}
		Write-Host "$line";
	}
}

Function gridscreentostring {
	for ($y = 0; $y -lt $gridRealSize; $y++) {
		for ($x = 0; $x -lt $gridRealSize; $x++) {
			if ($y -eq 0) {
				Write-Host -ForegroundColor white "Campo Minado";
				break;
			}
			if ($x -eq 0 -or $x -eq $gridRealSize - 1 -and $y -ne 0) {
				Write-Host -ForegroundColor black -BackgroundColor white -NoNewLine "  #  ";	
			} elseif (($y -eq $target[1] -and $x -eq $target[0]) -or ($y -eq $target[1] + 1 -and $x -eq $target[0])) {
				Write-Host -ForegroundColor red -BackgroundColor blue -NoNewLine "+---+";
			} else {
				Write-Host -ForegroundColor white -BackgroundColor blue -NoNewLine "     ";
			}
		}
		Write-Host -ForegroundColor white -BackgroundColor black "";
		for ($x = 0; $x -lt $gridRealSize; $x++) {
			if ($y -eq $target[1] -and $x -eq $target[0]) {
				Write-Host -ForegroundColor red -BackgroundColor blue -NoNewLine "| ";
				Write-Host -ForegroundColor white -BackgroundColor blue -NoNewLine "$($gridScreen[$y][$x])";
				Write-Host -ForegroundColor red -BackgroundColor blue -NoNewLine " |";
			} else {
				if ($gridScreen[$y][$x] -eq "B") {
					Write-Host -ForegroundColor black -BackgroundColor white -NoNewLine "  #  ";	
				} else {
					if ($gridScreen[$y][$x] -ne "O" -and $gridScreen[$y][$x] -ne "P") {
						Write-Host -ForegroundColor green -BackgroundColor blue -NoNewLine "  $($gridScreen[$y][$x])  ";
					} elseif ($gridScreen[$y][$x] -eq "P") {
						Write-Host -ForegroundColor red -BackgroundColor blue -NoNewLine "  $($gridScreen[$y][$x])  ";
					} else {
						Write-Host -ForegroundColor white -BackgroundColor blue -NoNewLine "  $($gridScreen[$y][$x])  ";
					}
				}
			}
		}
		Write-Host -ForegroundColor white -BackgroundColor black "";
	}
	if ($bandeiraSelected) {
		Write-Host -ForegroundColor red -BackgroundColor white -NoNewLine "`n`n`tCtrl"; 
	} else { 
		Write-Host -ForegroundColor red -BackgroundColor black -NoNewLine "`n`n`tCtrl"; 
	} 
	Write-Host -ForegroundColor red -BackgroundColor black -NoNewLine " - Bandeiras: $( If($bandeiras -lt 10) {"0" + $bandeiras } Else { $bandeiras } )`n`n`t";
	Write-Host -ForegroundColor yellow -BackgroundColor black -NoNewLine "q - Sair`n`n`t";
	Write-Host -ForegroundColor white -BackgroundColor black -NoNewLine "Use as setas para se mover e enter para selecionar`n";
}

Function click([Int] $x, [Int]$y) {
	if (-not($bandeiraSelected)) {
		if (-not($gridScreen[$y][$x] -eq "P")) {
			$gridScreen[$y][$x] = If ($grid[$y][$x] -ne ".") { $grid[$y][$x]; } Else { $gridScreen[$y][$x]; };
			if ($grid[$y][$x] -eq "X") {
				$global:rodando = $false;
				cls;
				Write-Host "Perdeu";
			}
			if ($primeiroClick) {
				$global:primeiroClick = $false;
				vaziosaoredor $x $y;
			}
			$grid[$y][$x] = ".";
			if (verificavenceu) {
				$global:rodando = $false;
				cls;
				Write-Host "Venceu";
			}
		}
	} else {
		if ($gridScreen[$y][$x] -ne "P" -and $gridScreen[$y][$x] -eq "O" -and $bandeiras -gt 0) {
			$gridScreen[$y][$x] = "P";
			$global:bandeiras--;
		} else {
			if ($gridScreen[$y][$x] -eq "P") {
				$gridScreen[$y][$x] = "O";
				$global:bandeiras++;
			}
		}
	}
}

Function verificavenceu {
	$venceu = $true;
	foreach ($y in $grid) {
		foreach ($x in $y) {
			if ($x -ne "B" -and $x -ne "." -and $x -ne "X") {
				$venceu = $false;
			}
		}
	}
	return $venceu;
}


Function execute {
	if ($rui.KeyAvailable) {
		resetcursor;
		gridscreentostring;
		$key = $rui.ReadKey();
		if ($key.virtualkeycode -eq 81) {
			$global:rodando = $false;
			Clear-Host;
			Write-Host "Saiu";
		}
		if ($key.virtualkeycode -eq 17) {
			$global:bandeiraSelected = !$bandeiraSelected;
		}
		if ($key.virtualkeycode -eq 37 -and ($gridScreen[$target[1]][$target[0] - 1] -ne "B")) {
			$target[0]--;
		}   
		if ($key.virtualkeycode -eq 38 -and ($gridScreen[$target[1] - 1][$target[0]] -ne "B"))	{
			$target[1]--;
		} 
		if ($key.virtualkeycode -eq 39 -and ($gridScreen[$target[1]][$target[0] + 1] -ne "B"))	{
			$target[0]++;
		}
		if ($key.virtualkeycode -eq 40 -and ($gridScreen[$target[1] + 1][$target[0]] -ne "B"))	{
			$target[1]++;
		}
		if ($key.virtualkeycode -eq 13) {
			if (-not($gridScreen[$target[1]][$target[0]] -eq "B")) {
				click $target[0] $target[1];
			}
		}
	}
}

Function resetcursor {
	$rui.CursorPosition = [System.Management.Automation.Host.Coordinates]::New(0, 0);
}

Function run {
	init;
	populagrid;
	filtragrid;
	gridscreentostring;
	while ($rodando) {
		execute;
    }
}

run;