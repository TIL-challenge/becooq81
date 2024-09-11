use sakila;

-- 1
select concat(first_name,' ', last_name) as name, phone from staff join address on staff.address_id=address.address_id
where staff.store_id=1;

-- 2
select concat(first_name, ' ', last_name) as name, email, phone, city.city, country.country
from customer join address on customer.address_id = address.address_id
		join city on address.city_id=city.city_id
		join country on country.country_id=city.country_id
where country='South Korea';

-- 3
select name, count(film_id)
from language left join film on language.language_id=film.language_id
group by language.name;

-- 4
select r.rental_id, c.customer_id, c.email, f.title
from rental r join customer c on r.customer_id=c.customer_id
			join inventory i on i.inventory_id=r.inventory_id
			join film f on f.film_id=i.film_id
order by r.rental_date limit 1;

-- 5
SELECT
    f.film_id,
    f.title,
    f.description,
    f.release_year,
    f.rental_duration,
    f.rental_rate,
    f.length,
    f.rating
FROM film f
LEFT JOIN inventory i ON f.film_id = i.film_id
LEFT JOIN rental r ON i.inventory_id = r.inventory_id
WHERE r.inventory_id IS NULL
ORDER BY f.film_id;

-- 6
select p.payment_id, s.staff_id '담당자 ID', s.email '담당자 이메일', p.payment_date '결재일'
from payment p join staff s on p.staff_id=s.staff_id
				join customer c on c.customer_id=p.customer_id
where c.email='EMILY.DIAZ@sakilacustomer.org' and p.payment_date >= '20050601' and p.payment_date < '20050801'
order by p.payment_id;

-- 7
select s.email '담당자 이메일', count(p.payment_id) '처리 건수'
from staff s join payment p on p.staff_id = s.staff_id
			join customer c on c.customer_id=p.customer_id
where p.payment_date >= '20050601' and p.payment_date < '20050801' and c.email='EMILY.DIAZ@sakilacustomer.org'
group by s.email
order by 2 desc;

-- 8
select f.title, fa.actor_id, concat(a.first_name, ' ', a.last_name) '이름'
from film f join film_actor fa on f.film_id = fa.film_id
			join actor a on fa.actor_id=a.actor_id
where f.title='ACADEMY DINOSAUR'
order by fa.actor_id asc;

-- 9
select a.actor_id, concat(a.first_name, ' ', a.last_name) '이름', count(f.film_id) '출연 작품 수'
from actor a join film_actor fa on a.actor_id=fa.actor_id
			join film f on f.film_id=fa.film_id
where a.actor_id in (select film_actor.actor_id from film_actor join film on film.film_id=film_actor.film_id where film.title='ACADEMY DINOSAUR')
group by a.actor_id having count(f.film_id)>=30
order by 3 desc;

-- 10
select city.city, country.country
from city join country on city.country_id=country.country_id
where length(city.city)=(select max(length(city)) from city);

-- 11
select film.title, film.length, film_category.category_id, category.name
from film join film_category on film.film_id=film_category.film_id
		join category on film_category.category_id=category.category_id
where film.length = (select max(film.length) from film) or film.length = (select min(film.length) from film)
order by film.title asc;

-- 12
select film.title, film.length, category.name, film.description
from film join film_category on film.film_id=film_category.film_id
			join category on film_category.category_id=category.category_id
where category.name='Animation' and film.length >= 180 and film.rating='G'
order by film.title asc;

-- 13
select film.title, film.rental_duration, 
case when film.rental_duration > (select avg(film.rental_duration) from film) then '긴편'
when film.rental_duration = (select avg(film.rental_duration) from film) then '평균'
else '짧은편' end as '상대 길이'
from film
where film.film_id=1;

-- 14
SELECT actor.actor_id, 
       actor.first_name, 
       actor.last_name, 
       COUNT(film.film_id) AS cnt
FROM actor
JOIN film_actor ON film_actor.actor_id = actor.actor_id
JOIN film ON film.film_id = film_actor.film_id
GROUP BY actor.actor_id, actor.first_name, actor.last_name
HAVING COUNT(film.film_id) = (
    SELECT MAX(film_count) 
    FROM (
        SELECT COUNT(film.film_id) AS film_count
        FROM film
        JOIN film_actor ON film_actor.film_id = film.film_id
        GROUP BY film_actor.actor_id
    ) AS subquery
);

-- 15
SELECT COUNT(DISTINCT inventory.inventory_id) AS '대여 가능 개수'
FROM inventory
JOIN film ON inventory.film_id = film.film_id
JOIN rental ON inventory.inventory_id = rental.inventory_id
WHERE film.title = 'ACADEMY DINOSAUR' AND inventory.store_id = 2 AND (rental.inventory_id IS NULL OR rental.return_date IS NOT NULL);

-- 16
SELECT rental.rental_date, date_add(rental.rental_date, interval film.rental_duration day) '마감일', film.rental_rate * datediff('20221231', rental.return_date) '연체료'
from rental join inventory on rental.inventory_id=inventory.inventory_id
		join film on film.film_id=inventory.film_id;

-- 17
select category.name, avg(film.length)
from category join film_category fc on category.category_id=fc.category_id
		join film on film.film_id=fc.film_id
group by fc.category_id
order by 2 desc;

