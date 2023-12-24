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
       "cs_id"      INTEGER NOT NULL UNIQUE,
       "dob"        INTEGER NOT NULL,
       "fname"      TEXT    NOT NULL,
       "lname"      TEXT    NOT NULL,
       "join_date"  INTEGER NOT NULL,
       "phone_nmbr" TEXT    NOT NULL,
       primary key ("cs_id")
);
CREATE TABLE "sales" (
       "cs_id"       INTEGER NOT NULL,
       "sale_id"     INTEGER NOT NULL UNIQUE,
       "total_price" INTEGER NOT NULL,
       PRIMARY KEY ("sale_id"),
       FOREIGN KEY ("cs_id")   REFERENCES customers("cs_id"),
       FOREIGN KEY ("sale_id") REFERENCES customers("cs_id")
);
create table "sale_details"(
       "id"      INTEGER NOT NULL UNIQUE,
       "sale_id" INTEGER NOT NULL,
       "ISBN"    INTEGER NOT NULL,
       "price"   REAL    NOT NULL,
       PRIMARY KEY ("ISBN","sale_id"),
       FOREIGN KEY ("sale_id") REFERENCES sales("sale_id"),
       FOREIGN KEY ("ISBN")    REFERENCES books("ISBN")
)
