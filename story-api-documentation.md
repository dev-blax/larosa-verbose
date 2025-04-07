# Story API Documentation

## 1. Upload Story

**Endpoint:** `POST /story/upload`

**Description:** This endpoint allows a user to upload a story. A story can consist of images or videos, and a user can upload up to 6 files at a time. Each file can have an associated caption.

### Request Parameters:

| Parameter | Type | Description | Constraints |
|-----------|------|-------------|------------|
| file | MultipartFile[] | Array of files (images/videos) to upload. | Must not exceed 6 files, content types must be valid (`image/*` or `video/*`). |
| profileId | Long | The ID of the profile uploading the story. | Must be non-null, profile must exist. |
| caption | String[] | Array of captions for each file. | Must not exceed the number of files; each file must have a corresponding caption. |

### Request Example:
```
POST /story/upload
Request Parameters:
file: Multiple image/video files.
profileId: 123
caption: ["Caption for first file", "Caption for second file"]
```

### Response Examples:

**Success:**
```json
{
  "message": "Story uploaded successfully"
}
```

**Error - Exceeding file limit:**
```json
{
  "message": "Exceeded maximum file limit (6)"
}
```

**Error - Mismatched file and caption count:**
```json
{
  "message": "The number of files must match the number of captions"
}
```

**Error - Invalid content type:**
```json
{
  "message": "Unsupported content type: application/pdf"
}
```

## 2. Delete Story

**Endpoint:** `DELETE /story/delete/{storyId}`

**Description:** This endpoint allows a user to delete their own story manually before it expires. The user must be the owner of the story.

### Path Variable:

| Variable | Type | Description | Constraints |
|----------|------|-------------|------------|
| storyId | Long | The ID of the story to be deleted. | Must be non-null, story must exist. |

### Request Parameters:

| Parameter | Type | Description | Constraints |
|-----------|------|-------------|------------|
| profileId | Long | The ID of the profile that owns the story. | Must match the profile that uploaded the story. |

### Request Example:
```
DELETE /story/delete/45
Request Parameter:
profileId: 123
```

### Response Examples:

**Success:**
```json
{
  "message": "Story deleted successfully"
}
```

**Error - Story not found:**
```json
{
  "message": "Story not found"
}
```

**Error - Unauthorized:**
```json
{
  "message": "You do not have permission to delete this story"
}
```

## 3. Retrieve Followed User Stories

**Endpoint:** `GET /story/user/followed-stories/{profileId}`

**Description:** This endpoint retrieves stories from the profiles that the user follows, grouped by the profile. It first retrieves the stories of profiles the user follows and has engaged with, then retrieves stories from profiles the user follows but has not engaged with.

### Path Variable:

| Variable | Type | Description | Constraints |
|----------|------|-------------|------------|
| profileId | Long | The ID of the profile requesting stories. | Must be a valid profile ID. |

### Response Examples:

**Success:**
```json
[
  {
    "profileId": 123,
    "name": "John Doe",
    "username": "johndoe",
    "stories": [
      {
        "storyId": 1,
        "captions": ["Vacation", "At the pool"],
        "names": ["story1.jpg", "story2.mp4"],
        "time": "2024-09-12T12:34:56"
      }
    ]
  },
  {
    "profileId": 456,
    "name": "Jane Smith",
    "username": "janesmith",
    "stories": [
      {
        "storyId": 2,
        "captions": ["At the beach"],
        "names": ["beach.jpg"],
        "time": "2024-09-11T11:22:33"
      }
    ]
  }
]
```

**Error - Invalid profile ID:**
```json
{
  "message": "Failed to retrieve stories: Profile does not exist"
}
```
