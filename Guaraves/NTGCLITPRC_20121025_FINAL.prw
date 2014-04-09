# include "Protheus.ch"
# include "FileIO.ch"

/*
Programa : NTGCLITPRC
Autor    : Emiliano Carvalho   
DATA     : 09/24/12 - DOM
Desc.    : Processar os clientes recebidos do servidor para atender    
           aos critérios do Automacão Comercial - Exclusivo para o PAF-ECF
           Vincular tabela de preço para consumidor final e tabela de preco
           para cnpj
Uso      : AP10 TERMINAL PAF-ECF - DBF 
*/                                           

User Function NTGCLITPRC()
		           
	// Main	              	
	//Local oMainDlg, oSay, oButtom, oFolder, oList
	Local sP1Descr, sP2Descr
	Local cPerg := 'NTGCLI'
	Local nMeter := 0		   
	lP1Realizado := .F.
	lP2Realizado       := .F.
	lAmbienteDBF       := .T.
	cCRLF              := CRLF	
	
    #IFDEF TOP
 		// deve ser usado apenas nos terminais PAF-ECF
	    lAmbienteDBF       := .F.
	    
    #ENDIF	
	
	// CliBrw
	oOK    := LoadBitmap(GetResources(),'br_verde')
	oNO    := LoadBitmap(GetResources(),'br_vermelho')
	oCF    := LoadBitmap(GetResources(),'br_azul')
	oPF    := LoadBitmap(GetResources(),'br_amarelo')
	aList  := {} // Vetor com elementos do Browse Clientes
	aListT := {} // Vetor com elementos do Browse Tabela de Precos
	//nX    := 0  
			                                        
	// tela principal
	oMainDlg := MSDialog():New(0,0,510,600,'Guaraves - Preparação de Cadastros [PAF-ECF]',,,,,CLR_BLACK,,,,.T.)
	                             
	// define a fonte padrão
	oFontTit := TFont():New('Tahoma',,-14,.T.,.T.)
	oFont    := TFont():New('Arial',,-11,.T.)
    
	// define os folders utilizados
	aFolder := {'Clientes', 'Tabelas de Preços'}
	oFolder := TFolder():New( 04, 04, aFolder, aFolder, oMainDlg,,,, .T.,,292,230)

	// paineis dos folders
	oPnlP1:= tPanel():New(0,0,””,oFolder:aDialogs[1],,,,,CLR_WHITE,100,100) // cria o painel	
	oPnlP2:= tPanel():New(0,0,””,oFolder:aDialogs[2],,,,,CLR_WHITE,100,100) // cria o painel	
	oPnlP1:align:= CONTROL_ALIGN_ALLCLIENT
	oPnlP2:align:= CONTROL_ALIGN_ALLCLIENT

	// Proc1
	oSayTit := TSay():New( 06, 06, {|| 'Clientes para o Terminal de Atendimento'},oPnlP1,, oFontTit,,,, .T.,CLR_BLACK)
	oSayTit:lTransparent := .T.
	sP1Descr := 'O propósito desta rotina é separar os clientes que utilizem condições de pagamento a vista e / ou cartão de crédito '
	sP1Descr := sP1Descr + 'e que atendam aos critérios do SPED Fiscal quanto ao preenchimento dos seus dados.'
	
	oSayDes := TSay():New( 16, 06, {||sP1Descr},oPnlP1,, oFont,,,, .T.,CLR_BLACK,,270,30)
	oSayDes:lTransparent := .T.
	oSayDes:lWordWrap := .T.
	
	// Proc2
	oSayTit := TSay():New( 06, 06, {|| 'Vincular Tabelas de Preços a Clientes'},oPnlP2,, oFontTit,,,, .T.,CLR_BLACK)
	oSayTit:lTransparent := .T.
	sP2Descr := 'O propósito desta rotina realizar a vinculação de uma tabela de preço para consumidor final e outra para pessoa jurídica.'
	
	oSayDes2 := TSay():New( 16, 06, {||sP2Descr},oPnlP2,, oFont,,,, .T.,CLR_BLACK,,270,30)
	oSayDes2 :lTransparent := .T.
	oSayDes2 :lWordWrap := .T.

	// botões
	// P1 Processa o cadastro de clientes
	oBtnP1_C := tButton():New(200,202,'Analisar',oPnlP1,{|| FP1Analizar(oMainDlg) },40,12,,oFont,,.T.,,'Analisa o cadastro e prepara para processamento')
	oBtnP1_P := tButton():New(200,246,'Processar',oPnlP1,{|| FP1Processar(oMainDlg) },40,12,,oFont,,.T.,,'Processa o cadastro analisado excluindo' + CRLF + 'os clientes que não atendem aos critérios')
	// P2 Processa a tabela de preços
	oBtnP2_C := tButton():New(200,202,'Vincular',oPnlP2,{|| FP2Vincular(oMainDlg) },40,12,,oFont,,.T.,,'Faz a análise e vinculação da tabela de preço conforme os parâmetros.')
	oBtnP2_P := tButton():New(200,246,'Processar',oPnlP2,{|| FP2Processar(oMainDlg) },40,12,,oFont,,.T.,,'Processa a vinculação da tabela de preço ao' + CRLF + 'cliente atualizando o cadastro do sistema')
                                                   
 	oBtnP1_P:Disable()
 	oBtnP2_P:Disable()
 	
 	// progress bar
 	oMeter:= tMeter():New(239,060,{|u|if(PCount()>0,nMeter:=u,nMeter)},100,oMainDlg,100,10,,.T.) // cria a régua
 	oMeter:lVisibleControl := .F.
 	oMeter:lPercentage := .F.
 	
    // botões gerais
	oBtnPergs  := tButton():New(238,004,'Parâmetros',oMainDlg,{||Pergunte(cPerg,.T.)},40,12,,oFont,,.T.)
	oBtnFechar := tButton():New(238,256,'Fechar',oMainDlg,{||oMainDlg:End()},40,12,,oFont,,.T.)

	// CliBrw Cliente ####################################################################################

	// fonte status
	oFont   := TFont():New('Arial',,-11,.T.,.T.)
                                      
	sP1Stat := 'Aguardando Operação:'	
	oSayDes := TSay():New( 33, 06, {||sP1Stat},oPnlP1,, oFont,,,, .T.,CLR_RED,,)
	oSayDes:lTransparent := .T.
                    
	// fonte browser
	oFont   := TFont():New('Arial',,-11,.T.)

	// Cria Browser Cliente
	
	oList := TCBrowse():New( 44 , 06, 280, 152,,;
	{'.:.','Código','Nome','CNPJ/CPF','Pessoa', 'Código Municipio', 'Pais', 'Tipo',;
	 'Inscr. Estadual', 'Inscr. Municipal', 'Endereço', 'Municipio', 'CEP', 'Bairro',;
	  'Estado', 'Email','Ocorrencia'},;
	{20,30,40,30,30,35,30,30,40,50,30,30,30,30,25,40,500},;
	oPnlP1,,,,,{||},,oFont,,,,,.F.,,.T.,,.F.,,, )

	// Inicializar Browser                    
	FUpdBrw(oMainDlg, 1)	

	// ###############################################################################################
		                     	
	// CliBrw Tabela de Preços #######################################################################

	// fonte status
	oFontT   := TFont():New('Arial',,-11,.T.,.T.)
                                      
	sP2Stat  := 'Aguardando Operação:'	
	oSayDesT := TSay():New( 33, 06, {||sP2Stat},oPnlP2,, oFontT,,,, .T.,CLR_RED,,)
	oSayDesT:lTransparent := .T.
                    
	// fonte browser
	oFontT   := TFont():New('Arial',,-11,.T.)

	// Cria Browser Tabela de Preços
	
	oListT := TCBrowse():New( 44 , 06, 280, 152,,;
	{'.:.','Código','Nome','CNPJ/CPF','Pessoa', 'Tipo', 'Tabela Atual', 'Tabela Definida','Ocorrência'},;
	{20,30,40,30,30,25,30,30,90},;
	oPnlP2,,,,,{||},,oFontT,,,,,.F.,,.T.,,.F.,,, )

	// Inicializar Browser Tabela de Preco
	FUpdBrw(oMainDlg, 3)	

	// ###############################################################################################

	// cria grupo de pergunta
	CriaSx1(cPerg)	
		                 
	// inicializa variaveis da pergunta
	Pergunte(cPerg,.F.)          
		    
	// abre o formulário
	oMainDlg:Activate(,,,.T.,,,)
	  	
Return

/*
Função   : FP1Analizar
Autor    : Emiliano Carvalho   
DATA     : 09/25/12 - SEG
Desc.    : Consulta a tabela de clientes e carrega no browser para processamento
           
Uso      : AP10 TERMINAL PAF-ECF - DBF 
*/                                           

Static Function FP1Analizar(oMDlg)
                             
    Local cAlias := 'SA1'
	Local aListAux  := {}
	
	aArea := GetArea()

	DbSelectArea(cAlias)  
	DbSetOrder(1)	 

	oBtnP1_C:Disable()
    
	cMsg := 'Iniciar Análise?'
	                               
	If lP1Realizado
		cMsg := "O processamento ja foi realizado!" + cCRLF +;
		 "Deseja realizar novamente a análise?"		
	EndIf
	
	If !(lAmbienteDBF)
	
		ApMsgInfo('Ambiente TOPCONNECT (DBAccess)!' + cCRLF +;
		'Não realize estas operações.','Análise Cliente')
		
	EndIf
	
 	If ApMsgNoYes(cMsg, "Analise Cliente")
                                
		sP1Stat := 'Aguardando Operação:'
		
		// carrega a tabela de clientes
		If SA1->(dbSeek(xFilial("SA1")))
			
			// informativos da inconsistencia encontrada
			// cErrFldVld - informa o campo que não atendeu para o cliente
			// cCliCond - informa os clientes q não são a vista / cartão

			aList := {}       
			aErrFldVld := {}                
		 	oMeter:lVisibleControl := .T.   
		 	oMeter:nTotal := SA1->(Reccount())
			oMeter:Set(1)
				
			While SA1->(!EOF()) .And. SA1->A1_FILIAL == xFilial("SA1")
                                  
				cErrFldVld := ''
				cErrCliCond := ''
				cCliCond   := ''
				lCliOk := .T.
                                            			
                // Clientes - valida cadastro NFe / SPED                                 
				IF (AllTrim(SA1->A1_CGC) == '') 
					lCliOk := .F.
					cErrFldVld := cErrFldVld + '| CNPJ / CPF - A1_CGC'					
				EndIf
				IF !(Upper(AllTrim(SA1->A1_PESSOA)) $ 'F|J') 
					lCliOk := .F.
					cErrFldVld := cErrFldVld + '| Pessoa - A1_PESSOA'					
				EndIf
				IF (AllTrim(SA1->A1_COD_MUN) == '') 
					lCliOk := .F.
					cErrFldVld := cErrFldVld + '| Código do Municipio - A1_COD_MUN'					
				EndIf              
				IF !(Upper(AllTrim(SA1->A1_TIPO)) $ 'F|R|L|S|X') 
					lCliOk := .F.
					cErrFldVld := cErrFldVld + '| Tipo - A1_TIPO'					
				EndIf
				IF (AllTrim(SA1->A1_INSCR) == '') .And. (Upper(AllTrim(SA1->A1_PESSOA)) == 'J') 
					lCliOk := .F.
					cErrFldVld := cErrFldVld + '| Inscrição Estadual - A1_INSCR'					
				EndIf
				IF (AllTrim(SA1->A1_INSCRM) == '') .And. (Upper(AllTrim(SA1->A1_PESSOA)) == 'J')
					lCliOk := .F.
					cErrFldVld := cErrFldVld + '| Inscrição Municipal - A1_INSCRM'					
				EndIf             
				IF (AllTrim(SA1->A1_END) == '') 
					lCliOk := .F.
					cErrFldVld := cErrFldVld + '| Endereco - A1_CGC'					
				EndIf
				IF (AllTrim(SA1->A1_MUN) == '') 
					lCliOk := .F.
					cErrFldVld := cErrFldVld + '| Municipio - A1_CGC'					
				EndIf
				IF (AllTrim(SA1->A1_CEP) == '') 
					lCliOk := .F.
					cErrFldVld := cErrFldVld + '| CEP - A1_CEP'					
				EndIf
				IF (AllTrim(SA1->A1_BAIRRO) == '') 
					lCliOk := .F.
					cErrFldVld := cErrFldVld + '| Bairro - A1_BAIRRO'					
				EndIf                   
				IF (AllTrim(SA1->A1_EST) == '') 
					lCliOk := .F.
					cErrFldVld := cErrFldVld + '| Estado - A1_EST'					
				EndIf
				IF (AllTrim(SA1->A1_EMAIL) == '') 
					lCliOk := .F.
					cErrFldVld := cErrFldVld + '| Email - A1_EMAIL'					
				EndIf							
                
				If lCliOk
					cCliOk := 'T'
				Else
					cCliOk := 'F'
				EndIf
						       
				If AllTrim(cErrFldVld) <> ''
					
					cErrFldVld := 'NFe/SPED - Inconsistencias ' + cErrFldVld
					
				EndIf
				
				aFldVldAux := {cCliOk, SA1->A1_COD, SA1->A1_NOME, cErrFldVld}			
				aadd(aErrFldVld, aFldVldAux)
                
    			// Clientes - a vista / cartão
				If !(SA1->A1_COND $ mv_par01) .and. !(SA1->A1_COND $ mv_par02)
					lCliOk := .F.
					cCliCond := SA1->A1_COND
					If lCliOk
						cCliOk := 'T'
					Else
						cCliOk := 'F'
					EndIf
					aFldVldAux := {cCliOk, SA1->A1_COD, SA1->A1_NOME, cCliCond}			
					aadd(aErrFldVld, aFldVldAux)
				EndIf
						
				aListAux := {If(lCliOk, 'T','F'),;
					SA1->A1_COD, SA1->A1_NOME, SA1->A1_CGC, SA1->A1_PESSOA, SA1->A1_COD_MUN,;
					SA1->A1_PAIS, SA1->A1_TIPO, SA1->A1_INSCR,;
					SA1->A1_INSCRM, SA1->A1_END, SA1->A1_MUN, SA1->A1_CEP,;
					SA1->A1_BAIRRO, SA1->A1_EST, SA1->A1_EMAIL, cErrFldVld + ' | ' + cCliCond,;
					CValToChar(SA1->(RecNo()))}			

				aadd(aList, aListAux)
									
				dbSkip()
				oMeter:Set(SA1->(RecNo()))				
				
			End
                
		 	/* 
		 	Ocorrencias - Criar log ou arquivo
		 	sLog := ''                       
			sLog := sLog + aErrFldVld[nl][1] + ', ' +;
            FT_FUse('NTGCLITPRC.LOG')    
                     
			
			*/       
            FGerarArqLog(aErrFldVld, 1)			

			// Dados Browser                    
			If Len(aList) > 0
				FUpdBrw(oMainDlg, 2)	
			Else
				FUpdBrw(oMainDlg, 1) // tabela vazia
			EndIf
		    
		 	//If ApMsgNoYes("Liberar para Processamento?", "Analise Cliente")
				oBtnP1_P:Enable()

			//Else
			//	oBtnP1_P:Disable()
				 	    
			//EndIf
		
			sP1Stat := 'Cadastro analisado, realize o processamento.'
				 	
		Else
			aList := {}
			FUpdBrw(oMainDlg, 1) // limpa browser
			ApMsgInfo('Registros não encontrados', "Análise Cliente")
        
		EndIf
		
	EndIf
			
	oBtnP1_C:Enable()

	RestArea(aArea)

 	oMeter:lVisibleControl := .F.
	
	
Return .T. 

/*
Função   : FP1Processar
Autor    : Emiliano Carvalho   
DATA     : 09/26/12 - SEG
Desc.    : Processa os clientes aprovados para o cadastro do PAF-ECF
           
Uso      : AP10 TERMINAL PAF-ECF - DBF 
*/                                           

Static Function FP1Processar(oMDlg)
                             	
    Local cAlias := 'SA1'
    Local cMsg 
	Local nI := 0                  
	Local lNAprov := .T.
	Local aListDel := {}
	Local aListAux  := {}

	aArea := GetArea()
			
	aListDel := ACLONE(aList)
	
	oBtnP1_C:Disable()
	oBtnP1_P:Disable()
    		
	// realiza teste caso todo o cadastro esteja inconsistente                
	For nI := 1 To Len( aList )
		
		If (aList[nI][1] == 'T')
				
			lNAprov := .F.
				
		EndIf	
			
	Next nI	

	If !(lAmbienteDBF)
	
		ApMsgInfo('Ambiente TOPCONNECT (DBAccess)!' + cCRLF +;
		'Não realize estas operações.','Análise Cliente')
		
	EndIf
			           
	cMsg := 'Esta operação irá excluir todos os clientes que não' + cCRLF +;		
		 'atendem aos critérios analisados.'+ cCRLF +;
		 'Iniciar o processamento?'		 	
	                               
	If lNAprov
		cMsg := "Não há um único cadastro aprovado!" + cCRLF +;
		 "Esta operação irá excluir todos os clientes que não" + cCRLF +;		
		 "atendem aos critérios analisados." + cCRLF +;		 
		 "Deseja realizar o processamento assim mesmo?"		
	EndIf
                                                                 
 	If ApMsgNoYes(cMsg, "Processamento Cliente") .And. lAmbienteDBF
 		
		// deletar clientes não aprovados
		DbSelectArea(cAlias)
		DbSetOrder(1)	 
		
		If SA1->(dbSeek(xFilial("SA1"))) 						

        	// progress bar                        
		 	oMeter:nTotal := Len(aListDel)
			oMeter:Set(1)
		
			For nI := 1 To Len(aListDel)

				// posiciona no registro			
				dbGoTo(Val(aListDel[nI][18]))

				If (aListDel[nI][1] =='F')  
		      			      	
					//ApMsgInfo('Deletando o registro : ' + StrZero(aList[nI][18]), "Processamento Cliente")
					If FPermiteExcluir(AllTrim(SA1->A1_COD), AllTrim(SA1->A1_LOJA))
				
						sP1Stat := 'Deletando: ' + AllTrim(SA1->A1_COD) + '-' + AllTrim(SA1->A1_LOJA) + ' Nome: ' + aListDel[nI][3]
					
						RecLock(cAlias,.F.)
						dbDelete()
						MsUnLock()         												                   

						If (Len(aListDel) > 0)
						 	
						 	aListDel[nI][17] := .T. // 'T'
						 	
						EndIf
						
					Else

						If (Len(aListDel) > 0)
						 	
						 	aListDel[nI][17] := .F. // 'F - Não Deletado'
						 	
						EndIf
					
					EndIf

				EndIf        
			
				oMeter:Set(nI)
			
			Next nI

		EndIf
		
		// processar a exibicão
		// Atualiza o browser apenas com os aprovados		
		If (Len(aListDel) > 0)
			
			aList := {}
		 	oMeter:lVisibleControl := .T.   
		 	oMeter:nTotal := Len(aListDel)
			oMeter:Set(1)
				
			For nI := 1 To Len(aListDel)

                lExcluirReg := aListDel[nI][17]
				If !(lExcluirReg)  
                                  
                	aListAux := {aListDel[nI][1],;
						aListDel[nI][2], aListDel[nI][3], aListDel[nI][4], aListDel[nI][5],;
						aListDel[nI][6], aListDel[nI][7], aListDel[nI][8], aListDel[nI][9],;
						aListDel[nI][10], aListDel[nI][11], aListDel[nI][12], aListDel[nI][13],;
						aListDel[nI][14], aListDel[nI][15], aListDel[nI][16], If(aListDel[nI][17],'T','F - Não Deletado'),;
						aListDel[nI][18]}			
			
					aadd(aList, aListAux)
	    		
				EndIf

				oMeter:Set(nI)
				
			End
			
		Else

			aList := {}
			FUpdBrw(oMainDlg, 1) // limpa browser
			ApMsgInfo('Sem ocorrencias para processar!', "Processamento Cliente")
        
		EndIf
		
		// Dados Browser                    
		If Len(aList) > 0
			FUpdBrw(oMainDlg, 2)	
		Else
			FUpdBrw(oMainDlg, 1) // caso não exista nenhum cadastro aprovado
		EndIf		
							
		sP1Stat := 'Cadastro Processado!'
		lP1Realizado	:= .T.
			
	EndIf
			
	oBtnP1_C:Enable()
	oBtnP1_P:Disable()	

	RestArea(aArea)
	    
 	oMeter:lVisibleControl := .F.   
	
Return .T. 

/*
Função   : FP2Vincular
Autor    : Emiliano Carvalho   
DATA     : 10/03/12 - QUA
Desc.    : Consulta clientes carregando o browser e 
           a tabela de preços para relacionar a tabela padrão
Uso      : AP10 TERMINAL PAF-ECF - DBF 
*/                                           

Static Function FP2Vincular(oMDlg)
                             
    Local cAlias    := 'SA1'
	Local lTabInfor := .T.
	Local aListAux  := {}
	Local lTabVOk   := .T.
	Local lTabPOk   := .T.
	
		
	If (Alltrim(mv_par03) == '') .Or. (Alltrim(mv_par04) == '')
	
		lTabInfor := .F. 

		ApMsgInfo('Tabelas de preços não informadas!' + cCRLF +;
		'Defina as tabelas padrão para os consumidores finais ' + cCRLF +;
		'e para as pessoas jurídicas','Tabela de Preço')
		
	EndIf      
	
	// valida se realmente as tabelas existem
	if !(FVldTabPrcV(Alltrim(mv_par03))) .OR. !(FVldTabPrcP(Alltrim(mv_par04)))

		lTabInfor := .F. 

		ApMsgInfo('Tabelas de preços não existem!' + cCRLF +;
		'Consulte as tabelas de preço e informe corretamente o código.' + cCRLF +;
		'Tecle F3 nos campos respectivos nos parâmetros.','Tabela de Preço')

	EndIf
		
	
	aArea := GetArea()

	DbSelectArea(cAlias)  
	DbSetOrder(1)	 

	oBtnP2_C:Disable()    
    
	cMsg := 'Iniciar Vinculação?'
	                               
	If lP2Realizado
		cMsg := "O processamento ja foi realizado!" + cCRLF +;
		 "Deseja realizar novamente a vinculação?"		
	EndIf
	
	If !(lAmbienteDBF)
	
		ApMsgInfo('Ambiente TOPCONNECT (DBAccess)!' + cCRLF +;
		'Não realize estas operações.','Tabela de Preço')
		
	EndIf
	                                      
	If !(lTabInfor)
		//ApMsgInfo('Operação não liberada.','Tabela de Preço')
	
 	ElseIf ApMsgNoYes(cMsg, "Tabela de Preço")
                                
		sP2Stat := 'Aguardando Operação:'
		
		// carrega a tabela de clientes
		If SA1->(dbSeek(xFilial("SA1")))
			
			aListT := {}       
			aErrFldVld := {}                
		 	oMeter:lVisibleControl := .T.   
		 	oMeter:nTotal := SA1->(Reccount())
			oMeter:Set(1)
				
			While SA1->(!EOF()) .And. (SA1->A1_FILIAL == xFilial("SA1"))
                                  
				cErrFldVld := 'Consumidor Final'
				lCliOk := .T.
				cCliOk := 'T'
                                            			
                // Identifica o cliente
				IF (Upper(AllTrim(SA1->A1_PESSOA)) == 'J') 
					
					cErrFldVld := 'Pessoa Jurídica'									
					lCliOk := .F.
					cCliOk := 'F'
				
				EndIf				
						
				aFldVldAux := {cCliOk, SA1->A1_COD, SA1->A1_NOME, cErrFldVld}			
				aadd(aErrFldVld, aFldVldAux)
                						
				aListAux := {cCliOk,;
					SA1->A1_COD, SA1->A1_NOME, SA1->A1_CGC, SA1->A1_PESSOA, SA1->A1_TIPO, SA1->A1_TABELA,;
					If(lCliOk, mv_par03,mv_par04), cErrFldVld ,;
					SA1->(RecNo()),SA1->A1_LOJA}			

				aadd(aListT, aListAux)
									
				dbSkip()
				oMeter:Set(SA1->(RecNo()))				
				
			End
                
		 	//Ocorrencias - log
            FGerarArqLog(aErrFldVld, 2)

			// Dados Browser                    
			If Len(aListT) > 0
				FUpdBrw(oMainDlg, 4)	
			Else
				FUpdBrw(oMainDlg, 3) // tabela vazia
			EndIf
		    
		 	//If ApMsgNoYes("Liberar para Processamento?", "Tabela de Preço")
				oBtnP2_P:Enable()

			//Else
			//	oBtnP2_P:Disable()
				 	    
			//EndIf
		
			sP2Stat := 'Cadastro vinculado, realize o processamento.'
			lP2Realizado	:= .T.
				 	
		Else
			aListT := {}
			FUpdBrw(oMainDlg, 3) // limpa browser
			ApMsgInfo('Registros não encontrados', "Tabela de Preço")
        
		EndIf
		
	EndIf
			
	oBtnP2_C:Enable()

	RestArea(aArea)

 	oMeter:lVisibleControl := .F.	
	
Return .T. 

/*
Função   : FP2Processar
Autor    : Emiliano Carvalho   
DATA     : 10/03/12 - QUA
Desc.    : Processa a vinculação das tabelas de preços no cadastro dos clientes
           
Uso      : AP10 TERMINAL PAF-ECF - DBF 
*/                                           

Static Function FP2Processar(oMDlg)
                             	
    Local cAlias := 'SA1'
    Local cMsg 
	Local nI := 0                  
	Local lNAprov := .T.
	Local aListProc := {}
	Local aListAux  := {}

	aArea := GetArea()
			
	oBtnP2_C:Disable()
	oBtnP2_P:Disable()
    
	aListProc := ACLONE(aListT)
		
	If !(lAmbienteDBF)
	
		ApMsgInfo('Ambiente TOPCONNECT (DBAccess)!' + cCRLF +;
		'Não realize estas operações.','Tabela de Preços')
		
	EndIf
			           
	cMsg := 'Esta operação irá atualizar a tabela de preços' + cCRLF +;		
		 'definidas nos parametros para todos os clientes.'+ cCRLF +;
		 'Iniciar o processamento?'		 	
	                                                                                                
 	If ApMsgNoYes(cMsg, "Processamento Tabela de Preço") .And. lAmbienteDBF
 		
		DbSelectArea(cAlias)  
		DbSetOrder(1)	 
        
		// Atualiza o browser apenas com os aprovados		
		If SA1->(dbSeek(xFilial("SA1"))) 
			
			aListT := {}
		 	oMeter:lVisibleControl := .T.   
		 	oMeter:nTotal := SA1->(RecCount())
			oMeter:Set(1)
				
			While SA1->(!EOF()) .And. SA1->A1_FILIAL == xFilial("SA1")
                                  
				cErrFldVld := 'Processado - Consumidor Final'
				lCliOk := .T.
				cCliOk := 'T'
                                            			
                // Identifica o cliente
				IF (Upper(AllTrim(SA1->A1_PESSOA)) == 'J') 
					
					cErrFldVld := 'Processado - Pessoa Jurídica'									
					lCliOk := .F.
					cCliOk := 'F'
				
				EndIf				
                						
				aListAux := {cCliOk,;
					SA1->A1_COD, SA1->A1_NOME, SA1->A1_CGC, SA1->A1_PESSOA, SA1->A1_TIPO, If(lCliOk, mv_par03,mv_par04),;
					If(lCliOk, mv_par03,mv_par04), cErrFldVld ,;
					SA1->(RecNo()),SA1->A1_LOJA}			

				aadd(aListT, aListAux)
						
				dbSkip()
				oMeter:Set(SA1->(RecNo()))
				
			End
			
		Else

			aListT := {}
			FUpdBrw(oMainDlg, 3) // limpa browser
			ApMsgInfo('Sem ocorrencias para processar!', "Processamento Tabela de Preço")
        
		EndIf
		
		// Dados Browser                    
		If Len(aListT) > 0
			FUpdBrw(oMainDlg, 4)	
		Else
			FUpdBrw(oMainDlg, 3) // caso não exista nenhum cadastro aprovado
		EndIf

		// atualizar a tabela de preços no cliente
		DbSelectArea(cAlias)
		DbSetOrder(1)	 
		
		If SA1->(dbSeek(xFilial("SA1")))

        	// progress bar                        
		 	oMeter:nTotal := Len( aListProc )
			oMeter:Set(1)
		
			For nI := 1 To Len( aListProc )
		   
				// atualizar a tabela de preços no cliente
				SA1->(dbSeek(xFilial("SA1")+aListProc[nI][2]+aListProc[nI][11]))						

				If Found()	

					RecLock(cAlias,.F.)
					// atualiza a tabela definida
					SA1->A1_TABELA := aListProc[nI][8]				
					MsUnLock()						

				EndIf
			
				oMeter:Set(nI)
			
			Next nI

		EndIf
							
		sP2Stat := 'Vinculação Processada!'
		lP2Realizado	:= .T.
			
	EndIf
			
	oBtnP2_C:Enable()
	oBtnP2_P:Disable()	

	RestArea(aArea)
	    
 	oMeter:lVisibleControl := .F.   
	
Return .T. 

/*
Função   : FUpdBrw
Autor    : Emiliano Carvalho   
DATA     : 09/25/12 - SEG
Desc.    : Carrega os dados do TCBrowser
           
Uso      : AP10 TERMINAL PAF-ECF - DBF 
*/                                           

Static Function FUpdBrw(oMDlg, nOpe)

	Local lOk := .T.
	Local aListAux := {}
		      	                         
	DO CASE
	CASE nOpe == 1                 		
		// inicializa conteudo CLIENTES
		aListAux := {'F', '', '', '', '', '', '',;
		, '', '', '', '', '', '', '',;
		, '', ''}		
		Aadd(aList, aListAux)

		oList:SetArray(aList)
		
		lOk := .F.
		// Monta a linha a ser exibina no Browse
		oList:bLine := {||{If(lOk,oOK,oNO),;
		aList[oList:nAt,02],;
		aList[oList:nAt,03],;
		aList[oList:nAt,04],;
		aList[oList:nAt,05],;
		aList[oList:nAt,06],;
		aList[oList:nAt,07],;
		aList[oList:nAt,08],;
		aList[oList:nAt,09],;
		aList[oList:nAt,10],;
		aList[oList:nAt,11],;
		aList[oList:nAt,12],;
		aList[oList:nAt,13],;
		aList[oList:nAt,14],;
		aList[oList:nAt,15],;	
		aList[oList:nAt,16],;
		aList[oList:nAt,17];
		}}
		  		
	CASE nOpe == 2
		// analises / processo CLIENTES
	                               		       
		oList:SetArray(aList)                           
			
		// Monta a linha a ser exibina no Browse
		oList:bLine := {||{ If(aList[oList:nAt,01]=='T',oOK,oNO),;
		aList[oList:nAt,02],;
		aList[oList:nAt,03],;
		aList[oList:nAt,04],;
		aList[oList:nAt,05],;
		aList[oList:nAt,06],;
		aList[oList:nAt,07],;
		aList[oList:nAt,08],;
		aList[oList:nAt,09],;
		aList[oList:nAt,10],;
		aList[oList:nAt,11],;
		aList[oList:nAt,12],;
		aList[oList:nAt,13],;
		aList[oList:nAt,14],;
		aList[oList:nAt,15],;
		aList[oList:nAt,16],;
		aList[oList:nAt,17];
		}}
		
		//Transform(aList[oList:nAT,04],'@E 99,999,999,999.99') } }
	
		// Evento de DuploClick (troca o valor do primeiro elemento do Vetor)
		//oList:bLDblClick := {|| aList[oList:nAt][1] :=;
		//!aList[oList:nAt][1],oList:DrawSelect() }

	CASE nOpe == 3
		// inicializa conteudo TABELA DE PREÇO
		aListAux := {'F', '', '', '', '', '', '', '', ''}		
		Aadd(aListT, aListAux)

		oListT:SetArray(aListT)
		
		lOk := .F.
		// Monta a linha a ser exibina no Browse
		oListT:bLine := {||{ If(lOk,oCF,oPF),;
		aListT[oListT:nAt,02],;
		aListT[oListT:nAt,03],;
		aListT[oListT:nAt,04],;
		aListT[oListT:nAt,05],;
		aListT[oListT:nAt,06],;
		aListT[oListT:nAt,07],;
		aListT[oListT:nAt,08],;
		aListT[oListT:nAt,09];
		}}
	CASE nOpe == 4
		// analises / processo TABELA DE PREÇO
	                               		       
		oListT:SetArray(aListT)                           
			
		// Monta a linha a ser exibina no Browse
		oListT:bLine := {||{ If(aListT[oListT:nAt,01]=='T',oCF,oPF),;
		aListT[oListT:nAt,02],;
		aListT[oListT:nAt,03],;
		aListT[oListT:nAt,04],;
		aListT[oListT:nAt,05],;
		aListT[oListT:nAt,06],;
		aListT[oListT:nAt,07],;
		aListT[oListT:nAt,08],;
		aListT[oListT:nAt,09];
		}}
		
		//Transform(aListT[oListT:nAT,04],'@E 99,999,999,999.99') } }
	
		// Evento de DuploClick (troca o valor do primeiro elemento do Vetor)
		//oListT:bLDblClick := {|| aListT[oListT:nAt][1] :=;
		//!aListT[oListT:nAt][1],oListT:DrawSelect() }
		
	ENDCASE

Return .T.

/*
Função   : FPermiteExcluir
Autor    : Emiliano Carvalho   
Data     : 09/30/12 - DOM
Desc.    : Integridade referencial
           
Uso      : AP10 TERMINAL PAF-ECF - DBF 
*/                                           

Static Function FPermiteExcluir(cCli, cLoj)
        
	Local lDeletar := .T.	
	Local aArea := GetArea()
	LOCAL nOrder := 0
	cSK1 := CriaTrab(NIL,.F.)
	cChave1 := "K1_FILIAL+K1_CLIENTE+K1_LOJA"
	
	cSF2 := CriaTrab(NIL,.F.)
	cChave2 := "F2_FILIAL+F2_CLIENTE+F2_LOJA"	
	
	cSE1 := CriaTrab(NIL,.F.)
	cChave3 := "E1_FILIAL+E1_CLIENTE+E1_LOJA"	
			
	// orcamentos
	DbSelectArea('SL1')
	DbSetOrder(6) //L1_FILIAL+L1_CLIENTE+L1_LOJA
		
	If SL1->(dbSeek(xFilial("SL1")+cCli+cLoj))
		lDeletar := .F.
	EndIf
						
	// Referencia do Contas a Receber
	//DbSelectArea('SK1')
	//DbSetOrder(4) //K1_FILIAL+K1_CLIENTE+K1_LOJA+DTOS(K1_VENCREA)
	// Temporário SK1
	dbSelectArea("SK1")
	IndRegua("SK1",cSK1,cChave1,,,"Selecionando Regs...")
	
	nOrder := RetIndex("SK1")   
	dbSetIndex(cSK1+OrdBagExt())

	dbsetOrder(nOrder+1)

	dbGoTop()
		
	If SK1->(dbSeek(xFilial("SK1")+cCli+cLoj))
		lDeletar := .F.
	EndIf
	
	// Cabeþalho das NF de Saida
	//DbSelectArea('SF2')
	//DbSetOrder(2) //ORDEM 2 F2_FILIAL+F2_CLIENTE+F2_LOJA+F2_DOC+F2_SERIE
	// Temporário SF2
	dbSelectArea("SF2")
	IndRegua("SF2",cSF2,cChave2,,,"Selecionando Regs...")
	
	nOrder := RetIndex("SF2")   
	dbSetIndex(cSF2+OrdBagExt())

	dbsetOrder(nOrder+1)

	dbGoTop()
		
	If SF2->(dbSeek(xFilial("SF2")+cCli+cLoj))
		lDeletar := .F.
	EndIf

	// contas a receber
	//DbSelectArea('SE1')
	//DbSetOrder(2) //ORDEM 2 E1_FILIAL+E1_CLIENTE+E1_LOJA+E1_PREFIXO+E1_NUM+E1_PARCELA+E1_TIPO
	// Temporário SE2
	dbSelectArea("SE1")
	IndRegua("SE1",cSE1,cChave3,,,"Selecionando Regs...")
	
	nOrder := RetIndex("SE1")   
	dbSetIndex(cSE1+OrdBagExt())

	dbsetOrder(nOrder+1)

	dbGoTop()
		
	If SE1->(dbSeek(xFilial("SE1")+cCli+cLoj))
		lDeletar := .F.
	EndIf
                     
    
    /* 
    VERIFICAR SE DEVEM SER INCLUÍDOS E QUANTO A NECESSIDADE DE CRIAR NOVOS ÍNDICES
    ANALISAR OUTRAS TABELAS USADAS NO TERMINAL PAF-ECF
	
	// conta corrente
	DbSelectArea('SE5')
	DbSetOrder(?) ORDEM 4 E5_FILIAL+E5_NATUREZ+E5_PREFIXO+E5_NUMERO+E5_PARCELA+E5_TIPO+DTOS(E5_DTDIGIT)+E5_RECPAG+E5_CLIFOR+E5_LOJA
		
	If SE5->(dbSeek(xFilial("SE5") + ????... + cCli+cLoj))
		lDeletar := .F.
	EndIf
    
    */
    
	RetIndex("SA1")

	Ferase(cSK1+OrdBagext())
	Ferase(cSF2+OrdBagext())
	Ferase(cSE1+OrdBagext())
	
	RestArea(aArea)
    
Return lDeletar

/*
Função   : FVldTabPrcV
Autor    : Emiliano Carvalho   
Data     : 10/22/12 - SEG
Desc.    : Valida a existencia das tabelas de preco a vista
           
Uso      : AP10 TERMINAL PAF-ECF - DBF 
*/                                           

Static Function FVldTabPrcV(cPerTabV)
        
	Local lTabelasOk := .T.	
	Local aArea := GetArea()
	Local aTabAVista := {}                                  
	cSeparador := ","      
	
	// individualiza
	aTabAVista := StrTokArr(cPerTabV,cSeparador)
	
	// tabelas de preços
	DbSelectArea('DA0')
	DbSetOrder(1) //DA0_FILIAL+DA0_CODTAB
		
	For nI := 1 To Len( aTabAVista )
	
		If !(DA0->(dbSeek(xFilial("DA0")+aTabAVista[nI])))
			lTabelasOk := .F.
		EndIf

	Next
						
	RestArea(aArea)
    
Return lTabelasOk

/*
Função   : FVldTabPrcP
Autor    : Emiliano Carvalho   
Data     : 10/22/12 - SEG
Desc.    : Valida a existencia das tabelas de preco a prazo
           
Uso      : AP10 TERMINAL PAF-ECF - DBF 
*/                                           

Static Function FVldTabPrcP(cPerTabP)
        
	Local lTabelasOk := .T.	
	Local aArea := GetArea()
	Local aTabAPrazo := {}              
	cSeparador := ","      
	
	// individualiza
	aTabAPrazo := StrTokArr(cPerTabP,cSeparador)

	// tabelas de preços
	DbSelectArea('DA0')
	DbSetOrder(1) //DA0_FILIAL+DA0_CODTAB
		
	For nI := 1 To Len( aTabAPrazo )
	
		If !(DA0->(dbSeek(xFilial("DA0")+aTabAPrazo[nI])))
			lTabelasOk := .F.
		EndIf

	Next
						
	RestArea(aArea)
    
Return lTabelasOk

/*
Função   : FGerarArqLog
Autor    : Emiliano Carvalho   
Data     : 10/02/12 - TER
Desc.    : Gerar arquivo de log
           
Uso      : AP10 TERMINAL PAF-ECF - DBF 
*/                                           

Static Function FGerarArqLog(aErrorLog, nOpe)
    
    Local cLine := DToC(Date()) + ' | USUARIO ' + AllTrim(UsrFullName(RetCodUsr()))  + CRLF
    Local cNomeArq := 'P1CLI_USR_'
    
    If nOpe == 2
    	cNomeArq := 'P2TAB_USR_'
    EndIf
    
    cNomeArq := cNomeArq + StrTran(AllTrim(UsrFullName(RetCodUsr())),' ','-')+'_'+StrTran(DToC(Date()),'/','-') + '.txt' 
                   
	For nI := 1 To Len( aErrorLog )

		cLine += aErrorLog[nI][1] + '|';
		+ aErrorLog[nI][2] + '|';		
		+ aErrorLog[nI][3] + '|';
		+ aErrorLog[nI][4] + CRLF

	Next
	
	MemoWrite('C:\Protheus_Data\spool\'+cNomeArq, cLine)                            

Return .T.


/*
Função   : FVldCadSped
Autor    : Emiliano Carvalho   
Data     : 09/25/12 - SEG
Desc.    : Valida alguns campos quanto ao correto preenchimento
           
Uso      : AP10 TERMINAL PAF-ECF - DBF 
*/                                           

Static Function FVldCadSped(cField)
                            

Return .T.

/*
Função   : CriaSx1
Autor    : Emiliano Carvalho   
Data     : 09/25/12 - SEG
Desc.    : Insere perguntas
           
Uso      : AP10 TERMINAL PAF-ECF - DBF 
*/                                           

Static Function CriaSx1(cPerg)

	Local aHelp := {}    
		
	// Texto do help em português , inglês, espanhol
	AAdd(aHelp, {{"Informe a(s) condições a vista, separadas"+CRLF+" por virgulas sem espaço."}, {""}, {""}})
	AAdd(aHelp, {{"Informe a(s) condições para cartão, "+CRLF+"separadas por virgulas sem espaço." }, {""}, {""}})
	AAdd(aHelp, {{"Tabela de preço padrão para"+CRLF+"consumidores finais."}, {""}, {""}})
	AAdd(aHelp, {{"Tabela de preço padrão para"+CRLF+"pessoas jurídicas." }, {""}, {""}})
	
	PutSx1(cPerg,"01","Condições a Vista","","","mv_ch1",;
		"C",30,00,00,"G","","SE4", "","","mv_Par01",;
		"","","","","","","","","","","","","","",;
		"","",aHelp[1,1],aHelp[1,2],aHelp[1,3],"")
	
	PutSx1(cPerg,"02","Condições p/ Cartões","","","mv_ch2",;
	"C",30,00,00,"G","","SE4", "","","mv_Par02",;
	"","","","","","","","","","","","","","",;
	"","",aHelp[2,1],aHelp[2,2],aHelp[2,3],"")

	PutSx1(cPerg,"03","Tabela p/ Consumidores","","","mv_ch3",;
	"C",30,00,00,"G","","DA0", "","","mv_Par03",;
	"","","","","","","","","","","","","","",;
	"","",aHelp[3,1],aHelp[3,2],aHelp[3,3],"")

	PutSx1(cPerg,"04","Tabela p/ Pessoas Jurídicas","","","mv_ch4",;
	"C",30,00,00,"G","","DA0", "","","mv_Par04",;
	"","","","","","","","","","","","","","",;
	"","",aHelp[4,1],aHelp[4,2],aHelp[4,3],"")

	// escreve no log servidor
	//conout("NTG Processou grupo de perguntas "+ cPerg)		
	
Return .T.

