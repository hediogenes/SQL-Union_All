/*
Задача: написать запрос, который объединил бы все 3 таблицы. Выводил поля за текущий месяц:
Date, Source, Campaign, Ad, SUM(Click), SUM(Cost), SUM(install), SUM(purchase).
Замечания:
- sourse в таблице 3 может быть больше 2
- пример поля date: '2021-05-01', пример поля datetime '2021-05-01 12:31:47'

Запрос был написан в синтаксисе PostgreSQL.
*/

SELECT a.Date, a.Source, a.Campaign, a.Ad, SUM(Click), SUM(Cost), SUM(install), SUM(purchase)
FROM (
		SELECT Date, 'A' AS Source, Campaign, Ad, SUM(Click) AS Click, SUM(Cost) AS Cost
		FROM "таблица 1"
		GROUP BY Date, Source, Campaign, Ad
		UNION ALL
		SELECT DATE(DateTime) AS Date, 'B' AS Source, Campaign, Ad, SUM(Click) AS Click, SUM(Cost) AS Cost
		FROM "таблица 2"
		GROUP BY DATE(DateTime), Source, Campaign, Ad
	 ) a INNER JOIN (
	 				  SELECT Date, Source, Campaign, Ad, SUM(install) AS install, SUM(purchase) AS purchase
	 				  FROM "таблица 3"
	 				  GROUP BY Date, Source, Campaign, Ad
	 				) b ON (a.Date = b.Date AND
	 						a.Source = b.Source AND
	 						a.Campaign = b.Campaign AND
	 						a.Ad = b.Ad)
GROUP BY a.Date, a.Source, a.Campaign, a.Ad
HAVING DATE_TRUNC('month', a.Date) = DATE_TRUNC('month', CURRENT_DATE);

/*
Описание решения.

Для меня основной сложностью в решении данной задачи стало отсутствие ключей, по которым можно было бы сделать джоины.
Без них я бы не смог (без предобработки) адекватно соединить таблицы 1 и 2 с таблицей 3, т.к. потенциально это могло бы привести к порче конечных данных.

Почему? Представим итоговый запрос. Чтобы работала агрегатная функция SUM(Click/Cost/install,purchase), необходимо сделать группровку с помощью GROUP BY.
GROUP BY нужно было бы делать по Date, Source, Campaign, Ad, т.е:
Мне бы показывались данные по кликам (и т.п.) от определенной рекламы, которая входит в состав рекламной кампании,
которая бы шла по определенному источнику, который бы работал в определенную дату.

Но остается вероятность, что последовательности Date, Source, Campaign, Ad могут повторяться и в таблцах 1,2, и в таблице 3. 
Из-за этого результирующие данные (без предобработки) после JOIN представляли бы собой все возможные комбинации подходящих под группировку значений.

Поэтому перед объединением таблиц необходимо сперва предобработать данные, чтобы свести количество комбинаций к нулю.
 */

-- Разбор запроса:
SELECT a.Date, a.Source, a.Campaign, a.Ad, SUM(Click), SUM(Cost), SUM(install), SUM(purchase) -- Отбирал необходимые колонки. Они будут отбираться из двух запросов: a и b.
FROM (
		SELECT Date, 'A' AS Source, Campaign, Ad, SUM(Click) AS Click, SUM(Cost) AS Cost
		FROM "таблица 1"
		GROUP BY Date, Source, Campaign, Ad
		UNION ALL
		SELECT DATE(DateTime) AS Date, 'B' AS Source, Campaign, Ad, SUM(Click) AS Click, SUM(Cost) AS Cost
		FROM "таблица 2"
		GROUP BY DATE(DateTime), Source, Campaign, Ad
		/*
		 В запросе a я объединил таблицу 1 и 2 с помощью оператора UNION ALL.
		  
		 Из таблицы 1 я отобрал Date, Campaign, Ad и добавил Source со значением A (source A).
		 По отобранным колонкам я суммировал Click, Cost.
		  
		 Из таблицы 2 я отобрал DateTime, Campaign, Ad и добавил Source со значением B (source B).
		 По отобранным колонкам я суммировал Click, Cost.
		 Также я преобразовал колонку DateTime из формата timestamp в date с помощью функции DATE().
		 */
	 ) a INNER JOIN (
	 				  SELECT Date, Source, Campaign, Ad, SUM(install) AS install, SUM(purchase) AS purchase
	 				  FROM "таблица 3"
	 				  GROUP BY Date, Source, Campaign, Ad
	 				) b ON (a.Date = b.Date AND
	 						a.Source = b.Source AND
	 						a.Campaign = b.Campaign AND
	 						a.Ad = b.Ad)
	 	/*
	 	 Делаю JOIN запроса a и b. Запрос b представляет собой предобработанную таблицу 3.
	 	  
	 	 Запрос b: Из таблицы 3 я отобрал Date, Source, Campaign, Ad.
	 	 По отобранным колонкам я суммировал install, purchase.
	 	  
	 	 JOIN будет делаться по Date, Source, Campaign, Ad.
	 	 */
GROUP BY a.Date, a.Source, a.Campaign, a.Ad -- Делаю группировку по a.Date, a.Source, a.Campaign, a.Ad, чтобы работало суммирование Click, Cost, install, purchase.
HAVING DATE_TRUNC('month', a.Date) = DATE_TRUNC('month', CURRENT_DATE) -- В HAVING я отфильтровал полученные данные, чтобы получить необходимые данные за текущий месяц.

/*
 P.S. В принципе в итоговом запросе можно не использовать функции SUM(), ее я оставил исключительно, чтобы соответствовать условиям ответа. Без них мой запрос был бы следующий:
 
SELECT a.Date, a.Source, a.Campaign, a.Ad, a.Click, a.Cost, b.install, b.purchase
FROM (
		SELECT Date, 'A' AS Source, Campaign, Ad, SUM(Click) AS Click, SUM(Cost) AS Cost
		FROM "таблица 1"
		GROUP BY Date, Source, Campaign, Ad
		UNION ALL
		SELECT DATE(DateTime) AS Date, 'B' AS Source, Campaign, Ad, SUM(Click) AS Click, SUM(Cost) AS Cost
		FROM "таблица 2"
		GROUP BY DATE(DateTime), Source, Campaign, Ad
	 ) a INNER JOIN (
	 				  SELECT Date, Source, Campaign, Ad, SUM(install) AS install, SUM(purchase) AS purchase
	 				  FROM "таблица 3"
	 				  GROUP BY Date, Source, Campaign, Ad
	 				) b ON (a.Date = b.Date AND
	 						a.Source = b.Source AND
	 						a.Campaign = b.Campaign AND
	 						a.Ad = b.Ad)
WHERE DATE_TRUNC('month', a.Date) = DATE_TRUNC('month', CURRENT_DATE) 
 */
		