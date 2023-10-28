// Copyright (c) RoochNetwork
// SPDX-License-Identifier: Apache-2.0

// <autogenerated>
//   This file was generated by dddappp code generator.
//   Any changes made to this file manually will be lost next time the file is regenerated.
// </autogenerated>

module rooch_examples::article {
    use moveos_std::event;
    use moveos_std::object_ref::{Self, ObjectRef};
    use moveos_std::object::ObjectID;
    use moveos_std::context::{Self, Context};
    use moveos_std::table::{Self, Table};
    use rooch_examples::comment::{Self, Comment};
    use std::error;
    use std::option;
    use std::signer;
    use std::string::String;
    friend rooch_examples::article_update_comment_logic;
    friend rooch_examples::article_remove_comment_logic;
    friend rooch_examples::article_add_comment_logic;
    friend rooch_examples::article_create_logic;
    friend rooch_examples::article_update_logic;
    friend rooch_examples::article_delete_logic;
    friend rooch_examples::article_aggregate;

    const ErrorIdAlreadyExists: u64 = 101;
    const ErrorDataTooLong: u64 = 102;
    const ErrorInappropriateVersion: u64 = 103;
    const ErrorNotGenesisAccount: u64 = 105;
    const ErrorIdNotFound: u64 = 106;

    struct CommentTableItemAdded has key {
        article_id: ObjectID,
        comment_seq_id: u64,
    }

    public fun initialize(ctx: &mut Context, account: &signer) {
        assert!(signer::address_of(account) == @rooch_examples, error::invalid_argument(ErrorNotGenesisAccount));
        let _ = ctx;
        let _ = account;
    }

    struct Article has key {
        version: u64,
        title: String,
        body: String,
        comments: Table<u64, Comment>,
        comment_seq_id_generator: CommentSeqIdGenerator,
    }

    struct CommentSeqIdGenerator has store {
        sequence: u64,
    }

    public(friend) fun current_comment_seq_id(article_obj: &ObjectRef<Article>): u64 {
        object_ref::borrow(article_obj).comment_seq_id_generator.sequence
    }

    public(friend) fun next_comment_seq_id(article_obj: &mut ObjectRef<Article>): u64 {
        let article = object_ref::borrow_mut(article_obj);
        article.comment_seq_id_generator.sequence = article.comment_seq_id_generator.sequence + 1;
        article.comment_seq_id_generator.sequence
    }

    /// get object id
    public fun id(article_obj: &ObjectRef<Article>): ObjectID {
        object_ref::id(article_obj)
    }

    public fun version(article: &Article): u64 {
        article.version
    }

    public fun title(article: &Article): String {
        article.title
    }

    public(friend) fun set_title(article: &mut Article, title: String) {
        assert!(std::string::length(&title) <= 200, ErrorDataTooLong);
        article.title = title;
    }

    public fun body(article: &Article): String {
        article.body
    }

    public(friend) fun set_body(article: &mut Article, body: String) {
        assert!(std::string::length(&body) <= 2000, ErrorDataTooLong);
        article.body = body;
    }

    public(friend) fun add_comment(article_obj: &mut ObjectRef<Article>, comment: Comment) {
        let article = object_ref::borrow_mut(article_obj);
        let comment_seq_id = comment::comment_seq_id(&comment);
        assert!(!table::contains(&article.comments, comment_seq_id), ErrorIdAlreadyExists);
        table::add(&mut article.comments, comment_seq_id, comment);
        //TODO enable event after refactor event API to remove `&mut Context`
        // event::emit(ctx, CommentTableItemAdded {
        //     article_id: id(article_obj),
        //     comment_seq_id,
        // });
    }

    public(friend) fun remove_comment(article_obj: &mut ObjectRef<Article>, comment_seq_id: u64) {
        let article = object_ref::borrow_mut(article_obj);
        assert!(table::contains(&article.comments, comment_seq_id), ErrorIdNotFound);
        let comment = table::remove(&mut article.comments, comment_seq_id);
        comment::drop_comment(comment);
    }

    public(friend) fun borrow_mut_comment(article_obj: &mut ObjectRef<Article>, comment_seq_id: u64): &mut Comment {
        table::borrow_mut(&mut object_ref::borrow_mut(article_obj).comments, comment_seq_id)
    }

    public fun borrow_comment(article_obj: &ObjectRef<Article>, comment_seq_id: u64): &Comment {
        table::borrow(&object_ref::borrow(article_obj).comments, comment_seq_id)
    }

    public fun comments_contains(article_obj: &ObjectRef<Article>, comment_seq_id: u64): bool {
        table::contains(&object_ref::borrow(article_obj).comments, comment_seq_id)
    }

    fun new_article(
        ctx: &mut Context,
        title: String,
        body: String,
    ): Article {
        assert!(std::string::length(&title) <= 200, ErrorDataTooLong);
        assert!(std::string::length(&body) <= 2000, ErrorDataTooLong);
        Article {
            version: 0,
            title,
            body,
            comments: table::new<u64, Comment>(ctx),
            comment_seq_id_generator: CommentSeqIdGenerator { sequence: 0, },
        }
    }

    struct CommentUpdated has key {
        id: ObjectID,
        version: u64,
        comment_seq_id: u64,
        commenter: String,
        body: String,
        owner: address,
    }

    public fun comment_updated_id(comment_updated: &CommentUpdated): ObjectID {
        comment_updated.id
    }

    public fun comment_updated_comment_seq_id(comment_updated: &CommentUpdated): u64 {
        comment_updated.comment_seq_id
    }

    public fun comment_updated_commenter(comment_updated: &CommentUpdated): String {
        comment_updated.commenter
    }

    public fun comment_updated_body(comment_updated: &CommentUpdated): String {
        comment_updated.body
    }

    public fun comment_updated_owner(comment_updated: &CommentUpdated): address {
        comment_updated.owner
    }

    public(friend) fun new_comment_updated(
        article_obj: &ObjectRef<Article>,
        comment_seq_id: u64,
        commenter: String,
        body: String,
        owner: address,
    ): CommentUpdated {
        let article = object_ref::borrow(article_obj);
        CommentUpdated {
            id: id(article_obj),
            version: version(article),
            comment_seq_id,
            commenter,
            body,
            owner,
        }
    }

    struct CommentRemoved has key {
        id: ObjectID,
        version: u64,
        comment_seq_id: u64,
    }

    public fun comment_removed_id(comment_removed: &CommentRemoved): ObjectID {
        comment_removed.id
    }

    public fun comment_removed_comment_seq_id(comment_removed: &CommentRemoved): u64 {
        comment_removed.comment_seq_id
    }

    public(friend) fun new_comment_removed(
        article_obj: &ObjectRef<Article>,
        comment_seq_id: u64,
    ): CommentRemoved {
        let article = object_ref::borrow(article_obj);
        CommentRemoved {
            id: id(article_obj),
            version: version(article),
            comment_seq_id,
        }
    }

    struct CommentAdded has key {
        id: ObjectID,
        version: u64,
        comment_seq_id: u64,
        commenter: String,
        body: String,
        owner: address,
    }

    public fun comment_added_id(comment_added: &CommentAdded): ObjectID {
        comment_added.id
    }

    public fun comment_added_comment_seq_id(comment_added: &CommentAdded): u64 {
        comment_added.comment_seq_id
    }

    public fun comment_added_commenter(comment_added: &CommentAdded): String {
        comment_added.commenter
    }

    public fun comment_added_body(comment_added: &CommentAdded): String {
        comment_added.body
    }

    public fun comment_added_owner(comment_added: &CommentAdded): address {
        comment_added.owner
    }

    public(friend) fun new_comment_added(
        article_obj: &ObjectRef<Article>,
        comment_seq_id: u64,
        commenter: String,
        body: String,
        owner: address,
    ): CommentAdded {
        let article = object_ref::borrow(article_obj);
        CommentAdded {
            id: id(article_obj),
            version: version(article),
            comment_seq_id,
            commenter,
            body,
            owner,
        }
    }

    struct ArticleCreated has key {
        id: option::Option<ObjectID>,
        title: String,
        body: String,
    }

    public fun article_created_id(article_created: &ArticleCreated): option::Option<ObjectID> {
        article_created.id
    }

    public(friend) fun set_article_created_id(article_created: &mut ArticleCreated, id: ObjectID) {
        article_created.id = option::some(id);
    }

    public fun article_created_title(article_created: &ArticleCreated): String {
        article_created.title
    }

    public fun article_created_body(article_created: &ArticleCreated): String {
        article_created.body
    }

    public(friend) fun new_article_created(
        title: String,
        body: String,
    ): ArticleCreated {
        ArticleCreated {
            id: option::none(),
            title,
            body,
        }
    }

    struct ArticleUpdated has key {
        id: ObjectID,
        version: u64,
        title: String,
        body: String,
    }

    public fun article_updated_id(article_updated: &ArticleUpdated): ObjectID {
        article_updated.id
    }

    public fun article_updated_title(article_updated: &ArticleUpdated): String {
        article_updated.title
    }

    public fun article_updated_body(article_updated: &ArticleUpdated): String {
        article_updated.body
    }

    public(friend) fun new_article_updated(
        article_obj: &ObjectRef<Article>,
        title: String,
        body: String,
    ): ArticleUpdated {
        let article = object_ref::borrow(article_obj);
        ArticleUpdated {
            id: id(article_obj),
            version: version(article),
            title,
            body,
        }
    }

    struct ArticleDeleted has key {
        id: ObjectID,
        version: u64,
    }

    public fun article_deleted_id(article_deleted: &ArticleDeleted): ObjectID {
        article_deleted.id
    }

    public(friend) fun new_article_deleted(
        article_obj: &ObjectRef<Article>,
    ): ArticleDeleted {
        let article = object_ref::borrow(article_obj);
        ArticleDeleted {
            id: id(article_obj),
            version: version(article),
        }
    }


    public(friend) fun create_article(
        ctx: &mut Context,
        title: String,
        body: String,
    ): ObjectRef<Article> {
        let article = new_article(
            ctx,
            title,
            body,
        );
        
        let article_obj = context::new_object(
            ctx,
            article,
        );
        article_obj
    }

    public(friend) fun update_version(article_obj: &mut ObjectRef<Article>) {
        let article = object_ref::borrow_mut(article_obj);
        article.version = article.version + 1;
    }

    public(friend) fun remove_article(article_obj: ObjectRef<Article>): Article {
        object_ref::remove(article_obj)
    }

    public fun get_article_mut(ctx: &mut Context, obj_id: ObjectID): &mut ObjectRef<Article> {
        context::borrow_object_mut_extend<Article>(ctx, obj_id)
    }

    public fun get_article(ctx: &mut Context, obj_id: ObjectID): &ObjectRef<Article> {
        context::borrow_object<Article>(ctx, obj_id)
    }

    public(friend) fun drop_article(article_obj: ObjectRef<Article>) {
        let article = object_ref::remove(article_obj);
        let Article {
            version: _version,
            title: _title,
            body: _body,
            comments,
            comment_seq_id_generator,
        } = article;
        let CommentSeqIdGenerator {
            sequence: _,
        } = comment_seq_id_generator;
        table::destroy_empty(comments);
    }

    public(friend) fun emit_comment_updated(ctx: &mut Context, comment_updated: CommentUpdated) {
        event::emit(ctx, comment_updated);
    }

    public(friend) fun emit_comment_removed(ctx: &mut Context, comment_removed: CommentRemoved) {
        event::emit(ctx, comment_removed);
    }

    public(friend) fun emit_comment_added(ctx: &mut Context, comment_added: CommentAdded) {
        event::emit(ctx, comment_added);
    }

    public(friend) fun emit_article_created(ctx: &mut Context, article_created: ArticleCreated) {
        event::emit(ctx, article_created);
    }

    public(friend) fun emit_article_updated(ctx: &mut Context, article_updated: ArticleUpdated) {
        event::emit(ctx, article_updated);
    }

    public(friend) fun emit_article_deleted(ctx: &mut Context, article_deleted: ArticleDeleted) {
        event::emit(ctx, article_deleted);
    }

}
