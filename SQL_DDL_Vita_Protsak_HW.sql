-- =========================================
-- 1. Create Database and Schema
-- =========================================
CREATE DATABASE Social_Media;


CREATE SCHEMA IF NOT EXISTS sm;

-- =========================================
-- 2. User Table (Parent)
-- =========================================
CREATE TABLE IF NOT EXISTS sm.user (
    user_id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================
-- 3. Profile Table (Child of User)
-- =========================================
CREATE TABLE IF NOT EXISTS sm.profile (
    profile_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL UNIQUE REFERENCES sm.user(user_id) ON DELETE CASCADE,
    full_name VARCHAR(100),
    bio TEXT,
    website VARCHAR(255),
    profile_picture_url VARCHAR(255),
    gender VARCHAR(10) CHECK (gender IN ('male','female','other')),
    birth_date DATE CHECK (birth_date > '2000-01-01')
);

-- =========================================
-- 4. Hashtag Table
-- =========================================
CREATE TABLE IF NOT EXISTS sm.hashtag (
    hashtag_id SERIAL PRIMARY KEY,
    tag_name VARCHAR(50) NOT NULL UNIQUE
);

-- =========================================
-- 5. Post Table (Child of User)
-- =========================================
CREATE TABLE IF NOT EXISTS sm.post (
    post_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES sm.user(user_id) ON DELETE CASCADE,
    caption TEXT,
    location VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- =========================================
-- 6. Comment Table (Child of Post and User)
-- =========================================
CREATE TABLE IF NOT EXISTS sm.comment (
    comment_id SERIAL PRIMARY KEY,
    post_id INT NOT NULL REFERENCES sm.post(post_id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES sm.user(user_id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================
-- 7. Like Table (Child of Post and User)
-- =========================================
CREATE TABLE IF NOT EXISTS sm.like (
    like_id SERIAL PRIMARY KEY,
    post_id INT NOT NULL REFERENCES sm.post(post_id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES sm.user(user_id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(post_id, user_id)
);


-- =========================================
-- 8. Post-Hashtag Table (Many-to-Many)
-- =========================================
CREATE TABLE IF NOT EXISTS sm.post_hashtag (
    post_id INT NOT NULL REFERENCES sm.post(post_id) ON DELETE CASCADE,
    hashtag_id INT NOT NULL REFERENCES sm.hashtag(hashtag_id) ON DELETE CASCADE,
    PRIMARY KEY(post_id, hashtag_id)
);


-- =========================================
-- 9. Follow Table (Self-Referencing Many-to-Many)
-- =========================================
CREATE TABLE IF NOT EXISTS sm.follow (
    follower_id INT NOT NULL REFERENCES sm.user(user_id) ON DELETE CASCADE,
    following_id INT NOT NULL REFERENCES sm.user(user_id) ON DELETE CASCADE,
    followed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(follower_id, following_id)
);

-- =========================================
-- 10. Message Table
-- =========================================
CREATE TABLE IF NOT EXISTS sm.message (
    message_id SERIAL PRIMARY KEY,
    sender_id INT NOT NULL REFERENCES sm.user(user_id) ON DELETE CASCADE,
    receiver_id INT NOT NULL REFERENCES sm.user(user_id) ON DELETE CASCADE,
    message_text TEXT NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_read BOOLEAN DEFAULT FALSE
);

-- =========================================
-- 11. Notification Table
-- =========================================
CREATE TABLE IF NOT EXISTS sm.notification (
    notification_id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES sm.user(user_id) ON DELETE CASCADE,
    actor_id INT NOT NULL REFERENCES sm.user(user_id) ON DELETE CASCADE,
    notification_type VARCHAR(20) NOT NULL CHECK (notification_type IN ('like','comment','follow')),
    related_post_id INT REFERENCES sm.post(post_id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================================
-- 12. Media Table
-- =========================================
CREATE TABLE IF NOT EXISTS sm.media (
    media_id SERIAL PRIMARY KEY,
    post_id INT NOT NULL REFERENCES sm.post(post_id) ON DELETE CASCADE,
    media_url VARCHAR(255),
    media_type VARCHAR(10) NOT NULL CHECK (media_type IN ('image','video')),
    order_index INT CHECK (order_index >= 0)
);

-- =========================================
-- 13. Sample Data Insertions
-- =========================================

-- 1. Users
INSERT INTO sm.user(username,email,password_hash)
VALUES 
('vita','vita@gmail.com','hash1'),
('max','max@gmail.com','hash2'),
('alice','alice@gmail.com','hash3'),
('bob','bob@gmail.com','hash4')
ON CONFLICT DO NOTHING;

-- 2. Profiles
INSERT INTO sm.profile(user_id, full_name, bio, website, profile_picture_url, gender, birth_date)
VALUES
(1,'Vita Protsak','Love travel','https://vita.com','https://vita.com/img1.jpg','female','2001-01-01'),
(2,'Max Smith','Food lover','https://max.com','https://max.com/img1.jpg','male','2002-05-10'),
(3,'Alice Green','Nature fan','https://alice.com','https://alice.com/img1.jpg','female','2003-03-15'),
(4,'Bob Brown','Sports enthusiast','https://bob.com','https://bob.com/img1.jpg','male','2000-12-12')
ON CONFLICT DO NOTHING;

-- 3. Hashtags
INSERT INTO sm.hashtag(tag_name)
VALUES ('travel'),('food'),('nature'),('sports')
ON CONFLICT DO NOTHING;

-- 4. Posts
INSERT INTO sm.post(user_id, caption, location)
VALUES
(1,'Exploring Paris!','Paris'),
(2,'Delicious pizza today','Rome'),
(3,'Hiking in the Alps','Switzerland'),
(4,'Football match highlights','London')
ON CONFLICT DO NOTHING;

-- 5. Comments
INSERT INTO sm.comment(post_id,user_id,text)
VALUES
(1,2,'Awesome!'),
(2,1,'Looks great!'),
(3,4,'So cool!'),
(4,3,'Nice shot!')
ON CONFLICT DO NOTHING;

-- 6. Likes
INSERT INTO sm."like"(post_id,user_id)
VALUES
(1,2),
(2,1),
(3,4),
(4,3)
ON CONFLICT DO NOTHING;

-- 7. Post_Hashtag
INSERT INTO sm.post_hashtag(post_id,hashtag_id)
VALUES
(1,1),
(2,2),
(3,3),
(4,4)
ON CONFLICT DO NOTHING;

-- 8. Follow
INSERT INTO sm.follow(follower_id,following_id)
VALUES 
(1,2),(2,1),
(3,4),(4,3)
ON CONFLICT DO NOTHING;

-- 9. Messages
INSERT INTO sm.message(sender_id,receiver_id,message_text)
VALUES 
(1,2,'Hello!'),(2,1,'Hi!'),
(3,4,'Hey, how are you?'),(4,3,'All good!')
ON CONFLICT DO NOTHING;

-- 10. Media
INSERT INTO sm.media(post_id,media_url,media_type,order_index)
VALUES
(1,'https://vita.com/img_post1.jpg','image',0),
(2,'https://max.com/img_post1.jpg','image',0),
(3,'https://alice.com/img_post1.jpg','image',0),
(4,'https://bob.com/img_post1.jpg','image',0)
ON CONFLICT DO NOTHING;

-- 11. Notifications
INSERT INTO sm.notification(user_id,actor_id,notification_type,related_post_id)
VALUES
(2,1,'like',1),
(1,2,'comment',2),
(4,3,'like',3),
(3,4,'comment',4)
ON CONFLICT DO NOTHING;