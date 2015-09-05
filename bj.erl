-module(bj).
-export([jugar/0]).

jugar()->
	io:fwrite("Bienvenido al juego de black jack\n"),
	jugarBJ(999).

jugarBJ(Balance) when Balance == 0 ->
	io:fwrite("Usted no tiene suficiente credito para continuar\n");

jugarBJ(Balance)->
	jugarBJ(Balance,1).

jugarBJ(Balance,Apuesta)->
	imprimirInstruccionesIniciales(Balance, Apuesta),
	case io:get_line("Introduzca su opcion: \n") of
        {error, Reason} ->
            {error, Reason};
        Opcion ->
            O = string:tokens(Opcion, " \n"),
            case O of 
                ["apostar", Monto] ->
					Aux = list_to_integer(Monto),
					if 
						Aux > Balance ->
							io:fwrite("No tiene suficiente credito para apostar tanto...\n"),
							jugarBJ(Balance,Apuesta);
						Aux < 0 ->
							io:fwrite("No puedes apostar con numeros negativos...\n"),
							jugarBJ(Balance,Apuesta);
						true ->
							jugarBJ(Balance - Aux, Apuesta + Aux)
					end;
                ["jugar"] ->
                    comenzarBJ(Balance, Apuesta);
                ["salir"] ->
                    balance(Balance + Apuesta);
                [_,_] ->
					jugarBJ(Balance,Apuesta);
                [_] ->
					jugarBJ(Balance,Apuesta)
            end
    end.	

comenzarBJ(Balance, Apuesta)->
	io:fwrite("Comienza el juego, barajando...\n\n"),
	Cartas = getMazoCartas(),
	[D1|M1] = Cartas,
	[D2|M2] = M1,
	[D3|M3] = M2,
	[D4|M4] = M3,
	io:fwrite("Repartiendo al Dealer \n\n"),
	CartasDealer = [D1,D2],
	io:fwrite("Repartiendo al Jugador \n\n"),
	CartasJugador = [D3,D4],
	ConteoDealer = contarCartas(CartasDealer),
	case esVU(ConteoDealer) of
		es21 ->
			io:fwrite("Usted ha perdido: el Dealer ha ligado 21...\n"),
			jugarBJ(Balance);		
		true ->
			io:fwrite("Continua el juego, el dealer no ha ligado 21...\n"),
			dibujarCartas("Dealer: ", CartasDealer),
			dibujarCartas("Jugador: ", CartasJugador),
			jugarBJ(CartasDealer,CartasJugador,M4,Balance,Apuesta)
		end.

jugarBJ(CartasDealer,CartasJugador,Mazo,Balance,Apuesta)->	
	io:format("Esta apostando: ~p~n",[Apuesta]),
	io:format("Balance restante: ~p~n",[Balance]),
	imprimirInstruccionesJuego(),
	{Acum,_} = contarCartas(CartasJugador),
	io:format("En este punto usted tiene ~p~n",[Acum]),
	dibujarCartas("Jugador: ", CartasJugador),
	{AcumD,_} = contarCartas(CartasDealer),
	io:format("y el Dealer tiene ~p~n",[AcumD]),
	dibujarCartas("Dealer: ", CartasDealer),
	case io:get_line("Introduzca su opcion: \n") of
    	{error, Reason} ->
        	{error, Reason};
        Opcion ->
            O = string:tokens(Opcion, " \n"),
            case O of 
                ["dame"] ->
					[Carta|NuevoMazo] = Mazo,
					NuevasCartasJugador = [Carta|CartasJugador],
					R = contarCartas(NuevasCartasJugador),
					case esVU(R) of
						es21 ->
							io:fwrite("Usted ha ganado:ha ligado 21...\n"),
							jugarBJ(Balance + Apuesta + Apuesta);		
						true ->	
							{AcumD2,_} = R,
							io:format("Usted ha ligado: ~p~n",[AcumD2]),
							if
								AcumD2 > 21 ->
									io:fwrite("Usted ha perdido:ha ligado mas de 21...\n"),
									jugarBJ(Balance);
								true ->
									jugarBJ(CartasDealer,NuevasCartasJugador,NuevoMazo,Balance,Apuesta)
							end,
							jugarBJ(CartasDealer,NuevasCartasJugador,NuevoMazo,Balance,Apuesta)
						end;
                ["paso"] ->
                    jugarDealerBJ(CartasDealer,CartasJugador,Mazo,Balance,Apuesta);
                ["salir"] ->
                    balance(Balance);
                [_] ->
					jugarBJ(CartasDealer,CartasJugador,Mazo,Balance,Apuesta)
            end
    end.

jugarDealerBJ(CartasDealer,CartasJugador,Mazo,Balance,Apuesta)->
	io:format("Esta apostando: ~p~n",[Apuesta]),
	io:format("Balance restante: ~p~n",[Balance]),
    lists:foreach(fun(E) -> io:format("~p~n",[E]) end,CartasDealer),
	PintasJugador = contarCartasMax(CartasJugador),
	PintasDealer = contarCartasMax(CartasDealer),
	if 
		PintasDealer =< 15 ->
			[Carta|NuevoMazo] = Mazo,
			NuevasCartasDealer = [Carta|CartasDealer],
			jugarDealerBJ(NuevasCartasDealer,CartasJugador,NuevoMazo,Balance,Apuesta);
		PintasDealer > 21 ->
			io:fwrite("Usted ha ganado: el Dealer ha ligado mas de 21...\n"),
			jugarBJ(Balance + Apuesta + Apuesta);		
		PintasDealer >= PintasJugador ->
			io:fwrite("Usted ha perdido: el Dealer ha ligado mas pintas...\n"),
			jugarBJ(Balance);	
		true ->
			io:fwrite("Usted ha ganado: el Dealer no ha ligado mas que usted...\n"),
			jugarBJ(Balance + Apuesta + Apuesta)	
	end
.
	
contarCartasMax(Cartas)->
	{Acum,Ases} = contarCartas(Cartas),
	contarCartasMax(Acum,Ases).

contarCartasMax(Acum,Ases)->
	case Ases of
		0 ->
			Acum;
		_ ->
			R = Acum + 10,
			if 
				R > 21 ->
					Acum;
				R == 21 ->
					21;
				true ->
					contarCartasMax(R,Ases-1)
			end
	end.
	

balance(Balance)->
	io:format("Saliendo del juego, su balance final es de: ~p",[Balance]).

dibujarCartas(Jugador,Cartas)->
	io:format("Jugador: ~p~n",[Jugador]),
	dibujarCartas(Cartas).

dibujarCartas(Cartas)->
	case Cartas of
		[H|T] ->
			{Carta,Pinta,_} = H,
			io:format("~p ~p~n",[Carta,Pinta]),
			dibujarCartas(T);
		[] ->
			true
	end.

esVU({Conteo,Ases})->	
	case Ases of
		0 ->
			if 
				Conteo == 21 -> es21;
				true -> true
			end;  
		_ ->
			if
				Conteo == 21 -> es21,
				esVU({Conteo + 10, Ases-1})
			end
	end.
	
contarCartas(L)->
	contarCartas(L,0,0).

contarCartas(Cartas,Acumulador,Ases)->
	case Cartas of
		[H|T] ->
			{Carta,_,Valor} = H,
			    case Carta of 
				as ->
					contarCartas(T,Acumulador + Valor,Ases + 1);
				_  ->
					contarCartas(T,Acumulador + Valor,Ases)
			    end;
		[] ->
			Resultado = {Acumulador,Ases},
			Resultado
	end.

getMazoCartas()->
	M = [{as,"D",1},	{as,"CR",1},	{as,"CN",1},	{as,"T",1},
	     {dos,"D",2},	{dos,"CR",2},	{dos,"CN",2},	{dos,"T",2},
	     {tres,"D",3},	{tres,"CR",3},	{tres,"CN",3},	{tres,"T",3},
	 	 {cuatro,"D",4},{cuatro,"CR",4},{cuatro,"CN",4},{cuatro,"T",4},
	 	 {cinco,"D",5},	{cinco,"CR",5},	{cinco,"CN",5},	{cinco,"T",5},
	 	 {seis,"D",6},	{seis,"CR",6},	{seis,"CN",6},	{seis,"T",6},
	 	 {siete,"D",7},	{siete,"CR",7},	{siete,"CN",7},	{siete,"T",7},
	 	 {ocho,"D",8},	{ocho,"CR",8},	{ocho,"CN",8},	{ocho,"T",8},
	 	 {nueve,"D",9},	{nueve,"CR",9},	{nueve,"CN",9},	{nueve,"T",9},
	 	 {diez,"D",10},	{diez,"CR",10},	{diez,"CN",10},	{diez,"T",10},
	 	 {jota,"D",10},	{jota,"CR",10},	{jota,"CN",10},	{jota,"T",10},
	 	 {reina,"D",10},{reina,"CR",10},{reina,"CN",10},{reina,"T",10},
	 	 {rey,"D",10},	{rey,"CR",10},	{rey,"CN",10},	{rey,"T",10}],
	shuffle:shuffle(M).

imprimirInstruccionesIniciales(Balance,Apuesta)->
	io:fwrite("########## Juego de BlackJack #######\n
	Las opciones son las siguientes: \n
	\"apostar\" + monto: para incrementar el monto de la apuesta\n
	\"jugar\" : para comenzar a jugar\n
	\"salir\": para terminar el juego\n\n
	Recuerde que si no selecciona un monto de apuesta, el valor por defecto es 1\n"),	
	io:format("Balance: ~p~n",[Balance]),	
	io:format("Apuesta: ~p~n",[Apuesta]).
	

imprimirInstruccionesJuego()->
	io:fwrite("########## Juego de BlackJack #######\n
	Las opciones son las siguientes: \n
	\"dame\": para recibir una carta del mazo\n
	\"paso\": para quedarse con las cartas servidas\n").
