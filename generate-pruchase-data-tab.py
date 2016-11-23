import random

shops = ['Game', 'Chekcers', 'OK', 'Makro', 'Friendly Grocer']
payment_types = ['Credit', 'Cash', 'Debit', 'Account']
products = ['Food', 'Clothes', 'Cutlery', 'Alcohol', 'Sweets', 'Furniture', 'Gifts']

for x in range(1000):

    data_date = (str(random.randint(2012,2013)) + '-' + str(random.randint(01,12)) + '-' + str(random.randint(01,28)))
    data_time = (str(random.randint(10,19)) + ':' + str(random.randint(10,55)))
    data_price = (str(random.randint(10,250)) + '.' + str(random.randint(10,99)))

    print(data_date + '\t' + data_time + '\t' + random.choice(shops) + '\t' + random.choice(products) + '\t' + data_price + '\t' + random.choice(payment_types))