# Comment APIs

## 1. Create New Comment

**Endpoint**: `POST /comments/new`  
**Description**: Creates a new comment on a specific post. If the user is unauthorized, `profileId` is set to null.

**Request Body:**

| Parameter  | Type | Description                   | Constraints |
|------------|------|-------------------------------|-------------|
| profileId  | Long | ID of the user making comment | Required    |
| postId     | Long | ID of the post to comment on  | Required    |
| message    | String | Content of the comment        | Required    |

**Response:**

- `200 OK`: Comment posted successfully.
- `400 Bad Request`: Validation errors.
- `401 Unauthorized`: User not authenticated.
- `500 Internal Server Error`: Unexpected error.

---

## 2. Reply to Comment

**Endpoint**: `POST /comments/reply`  
**Description**: Adds a reply to an existing comment.

**Request Body:**

| Parameter  | Type | Description                            | Constraints |
|------------|------|----------------------------------------|-------------|
| profileId  | Long | ID of the user replying                | Required    |
| postId     | Long | ID of the post                         | Required    |
| message    | String | Content of the reply                   | Required    |
| parentId   | Long | ID of the parent comment being replied | Required    |

**Response:**

- `200 OK`: Reply posted successfully.
- `400 Bad Request`: Validation errors.
- `401 Unauthorized`: User not authenticated.
- `500 Internal Server Error`: Unexpected error.

---

## 3. Get Comments for Post

**Endpoint**: `POST /comments/post`  
**Description**: Retrieves all comments on a given post.

**Request Body:**

| Parameter | Type | Description              | Constraints |
|-----------|------|--------------------------|-------------|
| postId    | Long | ID of the post           | Required    |

**Response:**

- `200 OK`: Returns list of comments.
- `400 Bad Request`: Validation errors.
- `404 Not Found`: No comments found.
- `500 Internal Server Error`: Unexpected error.

---

## 4. Get Replies for Comment

**Endpoint**: `POST /comments/post/reply`  
**Description**: Retrieves all replies to a specific comment.

**Request Body:**

| Parameter | Type | Description              | Constraints |
|-----------|------|--------------------------|-------------|
| parentId  | Long | ID of the parent comment | Required    |
| postId    | Long | ID of the post           | Required    |

**Response:**

- `200 OK`: Returns list of replies.
- `400 Bad Request`: Validation errors.
- `404 Not Found`: No replies found.
- `500 Internal Server Error`: Unexpected error.

---

## 5. Delete Comment

**Endpoint**: `POST /comments/delete`  
**Description**: Deletes a comment made by the user or on the user's post. Requires authentication.

**Request Body:**

| Parameter | Type    | Description                         | Constraints |
|-----------|---------|-------------------------------------|-------------|
| commentId | Long    | ID of the comment to be deleted     | Required    |
| ownPost   | boolean | Indicates if user owns the post     | Required    |

**Response:**

- `200 OK`: Comment deleted successfully.
- `400 Bad Request`: Validation errors.
- `401 Unauthorized`: User not authenticated.
- `403 Forbidden`: No permission to delete.
- `404 Not Found`: Comment not found.
- `500 Internal Server Error`: Unexpected error.

---

## 6. Like a Comment

**Endpoint**: `POST /comments/like`  
**Description**: Likes a specific comment. Requires authentication.

**Request Body:**

| Parameter  | Type | Description                    | Constraints |
|------------|------|--------------------------------|-------------|
| likerId    | Long | ID of the profile liking       | Required    |
| commentId  | Long | ID of the comment being liked  | Required    |

**Response:**

- `200 OK`: Comment liked successfully.
- `400 Bad Request`: Validation errors.
- `401 Unauthorized`: User not authenticated.
- `404 Not Found`: Comment not found.
- `500 Internal Server Error`: Unexpected error.
