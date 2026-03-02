# MongoDB Data Modeling

## Embedding vs Referencing

### Embed When
- One-to-few relationship
- Data accessed together
- Data doesn't change frequently

```javascript
// Embedded addresses
{
  _id: ObjectId("..."),
  name: "John Doe",
  addresses: [
    { type: "home", street: "123 Main St", city: "NYC" },
    { type: "work", street: "456 Office Blvd", city: "NYC" }
  ]
}
```

### Reference When
- One-to-many or many-to-many
- Data accessed independently
- Data changes frequently

```javascript
// Referenced orders
// users collection
{ _id: ObjectId("user1"), name: "John" }

// orders collection
{ _id: ObjectId("order1"), user_id: ObjectId("user1"), total: 100 }
```

## Common Patterns

### Subset Pattern
```javascript
// Store frequently accessed subset
{
  _id: ObjectId("..."),
  title: "Product Name",
  price: 99.99,
  // Subset of reviews for quick display
  recentReviews: [
    { rating: 5, text: "Great!" },
    { rating: 4, text: "Good" }
  ],
  reviewCount: 150
}
// Full reviews in separate collection
```

### Bucket Pattern
```javascript
// Time-series data
{
  sensor_id: "sensor1",
  date: ISODate("2024-01-15"),
  readings: [
    { time: ISODate("..."), value: 23.5 },
    { time: ISODate("..."), value: 24.1 }
  ],
  count: 2,
  sum: 47.6
}
```

### Computed Pattern
```javascript
// Pre-computed aggregations
{
  _id: ObjectId("..."),
  name: "Product",
  reviews: [...],
  // Computed fields
  averageRating: 4.5,
  totalReviews: 150
}
```

## Schema Validation

```javascript
db.createCollection("users", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "email"],
      properties: {
        name: { bsonType: "string" },
        email: { bsonType: "string", pattern: "^.+@.+$" },
        age: { bsonType: "int", minimum: 0 }
      }
    }
  }
})
```
