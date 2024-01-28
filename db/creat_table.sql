CREATE TABLE "books" (
       "ISBN"	   TEXT    NOT NULL UNIQUE,
       "ISBNhash"  INTEGER NOT NULL UNIQUE,
       "title"	   TEXT    NOT NULL,
       "writer"	   TEXT    NOT NULL,
       "publisher" TEXT    NOT NULL,
       "price"	   REAL    NOT NULL,
       PRIMARY KEY("ISBNhash","ISBN")
);
CREATE TABLE "customers" (
       "cs_id"        INTEGER NOT NULL UNIQUE,
       "name"         TEXT    NOT NULL,
       "surname"      TEXT    NOT NULL,
       "phone_number" TEXT    NOT NULL,
       "dob"          INTEGER NOT NULL,
       "join_date"    INTEGER NOT NULL,
       primary key ("cs_id")
);
CREATE TABLE "sales" (
       "sale_id"     INTEGER NOT NULL UNIQUE,
       "cs_id"       INTEGER NOT NULL,
       "total_price" INTEGER NOT NULL,
       PRIMARY KEY ("sale_id"),
       FOREIGN KEY ("cs_id")   REFERENCES customers("cs_id"),
       FOREIGN KEY ("sale_id") REFERENCES customers("cs_id")
);
CREATE TABLE "sale_details"(
       "id"       INTEGER NOT NULL UNIQUE,
       "sale_id"  INTEGER NOT NULL,
       "ISBNhash" INTEGER NOT NULL,
       "price"    REAL    NOT NULL,
       PRIMARY KEY ("ISBNhash","sale_id"),
       FOREIGN KEY ("sale_id")  REFERENCES sales("sale_id"),
       FOREIGN KEY ("ISBNhash") REFERENCES books("ISBNhash")
);
