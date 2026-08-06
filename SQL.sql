create table CampusRecrut(
id int primary key,
genero char(1),
media_1ano decimal(5,2),
ano1_central_outra varchar(20),
media_3ano decimal(5,2),
ano3_central_outra varchar(20),
tipo_especia_edu_sec varchar(15),
media_nota_sup decimal (5,2),
tipo_graduação varchar(20),
expe_trabalho varchar (3),
test_procent_emprego decimal (5,2),
pós_graduação_MBA varchar(10),
nota_MBA decimal(5,2),
status varchar(15),
salário decimal(10,2) null
)

	
BULK INSERT dbo.CampusRecrut
from 'C:\Windows\Temp\Campus\Placement_Data_Full_Class.csv'
with(FIRSTROW = 2,
FIELDTERMINATOR = ',',
ROWTERMINATOR = '0x0a',
TABLOCK
)

    select *
    from CampusRecrut

-- ==================================
--     Resumo geral do DATASET
-- ===================================

select count(status) as total_participantes, 
sum(case when status='Placed' then 1 else 0 end) as total_colocados,
cast(sum(case when status='Placed' then 1 else 0 end)as float) / count(status) * 100 as taxa_colocacao_prct

from CampusRecrut


-- =================================================================================================================
-- Qual tipo de especialização mais ganha ? e qual está mais no mercado de trabalho? 
--  R: Pessoas com especialização em 'Science' em média ganham mais, porem 'Commerce' é mais presente no mercado. 
-- =================================================================================================================
select  tipo_especia_edu_sec as Especialização,count(*) as Total_pessoas,count(*) - count(salário)as Pessoas_sem_salário,
         count(salário)as Pessoas_com_salário,
         avg(salário)as salário_médio
from CampusRecrut
group by tipo_especia_edu_sec
order by avg(salário) desc


-- ==================================================================================================
-- Desempenho academico influencia na colocação em 'Placement' no mercado de trabalho?
--  R: Sim, pessoas que possuem notas maiores tem maiores chances de estar no mercado de trabalho. 
-- ==================================================================================================

select status,avg(media_1ano) as media_1ano, avg(media_3ano)as media_3ano, avg(media_nota_sup)as media_nota_barchelado, avg(nota_MBA) as nota_MBA, count(status)as Participantes, sum(count(status)) over()  as TotalAmbos
from CampusRecrut
group by status
order by status desc


/* media 1° ano */

select distinct status, 
count(*) over(partition by status) as participantes,
min(media_1ano) over (partition by  status)  as min_nota_1ano,
percentile_cont(0.25) within group(order by media_1ano) over (partition by status) as perc_25,
percentile_cont(0.50) within group (order by media_1ano) over (partition by status) as mediana_1ano,
percentile_cont(0.75) within group (order by media_1ano) over (partition by status) as perc_75,
max(media_1ano) over (partition by status) as max_nota_1ano,
stdev(media_1ano) over (partition by status) as disvio_1ano
    
   
from CampusRecrut
order by status desc




/* media 3° ano */

select distinct status, count(status) over (partition by status) as participantes,
min(media_3ano) over (partition by status ) as min_nota_3ano,
percentile_cont(0.25) within group (order by media_3ano) over (partition by status) as perc_25, 
percentile_cont(0.50) within group (order by media_3ano) over (partition by status) as mediana_3ano,
percentile_cont(0.75) within group (order by media_3ano) over (partition by status) as perc_75,
max(media_3ano) over (partition by status) as max_nota_3ano,
stdev(media_3ano) over (partition by status) as desvio_3ano


from CampusRecrut
order by status desc

/* Media MBA */

select distinct status, count(*) over (partition by status) as participantes,
min(nota_MBA)  over (partition by status) as min_nota,
percentile_cont(0.25) within group (order by nota_MBA) over (partition by status) as perc_25,
percentile_cont(0.50) within group (order by nota_MBA) over (partition by status) as mediana_nota,
percentile_cont(0.75) within group (order by nota_MBA) over (partition by status) as perc_75,
max(nota_MBA) over (partition by status) as max_nota,
stdev(nota_MBA) over (partition by status) as desvio

from CampusRecrut
order by status desc


/*
25% das 148 pessoas, 37 ficaram com igual ou mneos de 63 de nota (Placed)
25% das 67 pessoas, 17 ficaram com igual ou menos 51 de nota (Not Placed)
-
50% das 148 pessoas, 74 ficaram com igual ou menos 68 de nota(Placed)
50% das 67 pessoas, 34 ficaram com igual ou menos 60,33 de nota(Not Placed)
-
75% das 148 pessoas, 111 ficaram com igual ou menos 75,25 de nota(Placed)
75% das 67 pessoas, 50 ficaram com igual ou menos de 64 de nota(Not Placed)

Das Pessoas em 'Placed' das 148, 37 ficarom com 25% ou menos de nota, 25% entre 50% 37 pessoas, 50% entre 75% 37 pessoas e acima de 75% 37  pessoas.
Das Pessoas em 'Not Placed' das 67, 17 ficarom com 25% ou menos de nota, 25% entre 50% 17 pessoas, 50% entre 75% 16 pessoas e acima de 75% 17 pessoas.

#Notas
1°ano

Placed      148	 min-49.00	 25%- 65	50%- 72,5	75%- 78,125   max-89.40	  desvio- 8,71544522846821
Not Placed  67	 min-40.89	 25%- 52	50%- 56,28	75%- 63	      max-77.80   desvio- 8,39424587543616


3°ano

Placed     148    min-50.83	  25%- 63 	50%- 68	    75%- 75,25	 max-97.70   desvio- 9,32926780109474
Not Placed  67    min-37.00	  25%- 51 	50%- 60,33	75%- 64	     max-82.00	 desvio- 9,91408995557439


MBA

Placed	    148	  min-52.38	  25%- 57,77	50%- 62,245	 75%- 66,76	    max-77.89	desvio- 5,8845829040145
Not Placed	67	  min-51.21	  25%- 58,48	50%- 60,69	 75%- 65,40	    max-75.71	desvio- 5,70568876302558

--Pessoas em 'Placed' tem um média de nota maior em todas as porcentagens em  relação aos 'Not Placed', tendo menos relevancia nas notas do MBA.
Também um devio de padrão 2,9 no 1°ano,  2,7 no 3°ano e  0,05 no MBA, considerados baixos.
*/ 


-- ==================================================================================================
-- Pessoas come experiencia em trabalho ganham mais?
--  R: Sim, com uma porcentagem de 2,1%(5500) maior em relação quem não tem experiência de trabalho.
-- ==================================================================================================
select distinct status,expe_trabalho,
count(status) over (partition by status,expe_trabalho) as pessoas,
count(status) over (partition by status) as  total_pessoas

from CampusRecrut


select distinct
    expe_trabalho,
    count(*) over(partition by expe_trabalho) as pessoas,
    avg(salário) over(partition by expe_trabalho) as media_salario,
    percentile_cont(0.50) within group (order by salário) over(partition by expe_trabalho) as mediana_salario,
    min(salário) over(partition by expe_trabalho) as min_salario,
    max(salário) over(partition by expe_trabalho) as max_salario,
    stdev(salário) over(partition by expe_trabalho) as desvio_salario
from CampusRecrut
where status = 'Placed'


-- ==================================================================
-- Existe uma diferença de salário entre homens e mulheres 
--  R: Sim, pela mediana homens ganham R$20.000 a mais que mulheres.
-- ==================================================================
select distinct genero, count(*) over (partition by genero) as Pessoas,
min(salário) over (partition by genero) as min_salario,
percentile_cont(0.25) within group (order by salário) over (partition by genero) as salario_25,
avg(salário) over (partition by genero)as salario_media,
percentile_cont(0.50) within group (order by salário) over (partition by genero ) as salario_mediana,
percentile_cont(0.75) within group (order by salário) over (partition by genero) as salario_75,
max(salário) over (partition by genero) as salario_max,
stdev(salário) over (partition by genero) as desvio

from CampusRecrut

-- ==================================================================
-- Top 10 maiores salários ordenados por Genero e Tipo de graduação
-- ==================================================================

select genero, salário,tipo_graduação
from(select genero,salário,tipo_graduação, ROW_NUMBER() over (partition by genero order by salário desc) rs
 from CampusRecrut
where status = 'Placed'
)t
where rs <=10


/* Procedure */

CREATE PROCEDURE sp_genero_calculo
@grupo nvarchar(50),
@coluna nvarchar(50)
as
begin
    declare @sql nvarchar(max)
    set @sql = N'

select distinct '+ @grupo + N', count(*) over (partition by '+ @grupo + N') as Pessoas,
min('+ @coluna + N') over (partition by '+ @grupo+ N') as min_salario,
percentile_cont(0.25) within group (order by '+ @coluna + N') over (partition by '+ @grupo+ N') as salario_25,
avg('+ @coluna + N') over (partition by '+ @grupo+ N')as salario_media,
percentile_cont(0.50) within group (order by '+ @coluna + N') over (partition by '+ @grupo+ N' ) as salario_mediana,
percentile_cont(0.75) within group (order by '+ @coluna + N') over (partition by '+ @grupo+ N') as salario_75,
max('+ @coluna + N') over (partition by '+ @grupo+ N') as salario_max,
stdev('+ @coluna + N') over (partition by '+ @grupo+ N') as desvio

from CampusRecrut'
exec sp_executesql @sql
end

exec sp_genero_calculo 'genero', 'salário'








