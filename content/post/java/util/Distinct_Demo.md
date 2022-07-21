---
title: "Distinct_Demo"
discriptions: "Distinct_Demo"
date: 2019-03-21T22:11:09+08:00
author: Pismery Liu
archives: "2019"
tags: [工具类,Java]
categories: [Java]
showtoc: true
---

Java 8 去重写法
<!--more-->

```Java
public class DistinctDemo {
    public static void main(String[] args) {
        List<Record> records = getRecords();

        System.out.println("Distinct by custom key");
        records.stream()
                .filter(distinctByKey(CustomKey::new))
                .forEach(System.out::println);

        System.out.println("Distinct by field");
        records.stream()
                .filter(distinctByKeys(Record::getId, Record::getName))
                .forEach(System.out::println);

    }

    private static List<Record> getRecords() {
        List<Record> records = new ArrayList<>();

        records.add(new Record(1L, 10L, "record1", "record1@email.com", "GZ"));
        records.add(new Record(1L, 20L, "record1", "record1@email.com", "GZ"));
        records.add(new Record(2L, 30L, "record2", "record2@email.com", "GZ"));
        records.add(new Record(2L, 40L, "record2", "record2@email.com", "GZ"));
        records.add(new Record(3L, 50L, "record3", "record3@email.com", "GZ"));

        return records;
    }

    @SafeVarargs
    private static <T> Predicate<T> distinctByKeys(Function<? super T, ?>... keyExtractors) {
        final Map<List<?>, Boolean> seen = new ConcurrentHashMap<>();

        return t -> {
            final List<?> list = Arrays.stream(keyExtractors)
                    .map(key -> key.apply(t))
                    .collect(Collectors.toList());
            return seen.putIfAbsent(list,Boolean.TRUE) == null;
        };
    }

    private static <T> Predicate<T> distinctByKey(Function<? super T, Object> keyExtractor) {
        Map<Object, Boolean> seen = new ConcurrentHashMap<>();
        return t -> seen.putIfAbsent(keyExtractor.apply(t), Boolean.TRUE) == null;
    }

    @EqualsAndHashCode
    private static class CustomKey {
        private long id;
        private String name;

        CustomKey(final Record record) {
            this.id = record.getId();
            this.name = record.getName();
        }
    }

    @Getter
    @Setter
    @AllArgsConstructor
    @NoArgsConstructor
    private static class Record {
        private long id;
        private long count;
        private String name;
        private String email;
        private String location;

        @Override
        public String toString() {
            return "Record [id=" + id + ", count=" + count + ", name=" + name +
                    ", email=" + email + ", location="
                    + location + "]";
        }
    }
}

// 运行结果
Distinct by custom key
Record [id=1, count=10, name=record1, email=record1@email.com, location=GZ]
Record [id=2, count=30, name=record2, email=record2@email.com, location=GZ]
Record [id=3, count=50, name=record3, email=record3@email.com, location=GZ]
Distinct by field
Record [id=1, count=10, name=record1, email=record1@email.com, location=GZ]
Record [id=2, count=30, name=record2, email=record2@email.com, location=GZ]
Record [id=3, count=50, name=record3, email=record3@email.com, location=GZ]
```