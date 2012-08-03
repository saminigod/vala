/* valacodewriter.vala
 *
 * Copyright (C) 2006-2010  Jürg Billeter
 * Copyright (C) 2006-2008  Raffaele Sandrini
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.

 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.

 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA
 *
 * Author:
 * 	Jürg Billeter <j@bitron.ch>
 *	Raffaele Sandrini <raffaele@sandrini.ch>
 */


/**
 * Code visitor generating Vala API file for the public interface.
 */
public class Vala.CodeWriter : CodeVisitor {
	private CodeContext context;
	
	FileStream stream;
	
	int indent;
	/* at begin of line */
	bool bol = true;

	Scope current_scope;

	CodeWriterType type;

	string? override_header = null;
	string? header_to_override = null;

	public CodeWriter (CodeWriterType type = CodeWriterType.EXTERNAL) {
		this.type = type;
	}

	/**
	 * Allows overriding of a specific cheader in the output
	 * @param original orignal cheader to override
	 * @param replacement cheader to replace original with
	 */
	public void set_cheader_override (string original, string replacement)
	{
		header_to_override = original;
		override_header = replacement;
	}

	/**
	 * Writes the public interface of the specified code context into the
	 * specified file.
	 *
	 * @param context  a code context
	 * @param filename a relative or absolute filename
	 */
	public void write_file (CodeContext context, string filename) {
		var file_exists = FileUtils.test (filename, FileTest.EXISTS);
		var temp_filename = filename + ".valatmp";
		this.context = context;

		if (file_exists) {
			stream = FileStream.open (temp_filename, "w");
		} else {
			stream = FileStream.open (filename, "w");
		}

		if (stream == null) {
			Report.error (null, "unable to open `%s' for writing".printf (filename));
			return;
		}

		var header = context.version_header ?
			"/* %s generated by %s %s, do not modify. */".printf (Path.get_basename (filename), Environment.get_prgname (), Config.BUILD_VERSION) :
			"/* %s generated by %s, do not modify. */".printf (Path.get_basename (filename), Environment.get_prgname ());
		write_string (header);
		write_newline ();
		write_newline ();

		current_scope = context.root.scope;

		context.accept (this);

		current_scope = null;

		stream = null;

		if (file_exists) {
			var changed = true;

			try {
				var old_file = new MappedFile (filename, false);
				var new_file = new MappedFile (temp_filename, false);
				var len = old_file.get_length ();
				if (len == new_file.get_length ()) {
					if (Memory.cmp (old_file.get_contents (), new_file.get_contents (), len) == 0) {
						changed = false;
					}
				}
				old_file = null;
				new_file = null;
			} catch (FileError e) {
				// assume changed if mmap comparison doesn't work
			}

			if (changed) {
				FileUtils.rename (temp_filename, filename);
			} else {
				FileUtils.unlink (temp_filename);
			}
		}

	}

	public override void visit_using_directive (UsingDirective ns) {
		if (type == CodeWriterType.FAST) {
			write_string ("using ");

			var symbols = new GLib.List<UnresolvedSymbol> ();
			var sym = (UnresolvedSymbol) ns.namespace_symbol;
			symbols.prepend (sym);

			while ((sym = sym.inner) != null) {
				symbols.prepend (sym);
			}

			write_string (symbols.nth_data (0).name);

			for (int i = 1; i < symbols.length (); i++) {
				write_string (".");
				write_string (symbols.nth_data (i).name);
			}

			write_string (";\n");
		}
	}

	public override void visit_namespace (Namespace ns) {
		if (ns.external_package) {
			return;
		}

		if (ns.name == null)  {
			ns.accept_children (this);
			return;
		}

		write_attributes (ns);

		write_indent ();
		write_string ("namespace ");
		write_identifier (ns.name);
		write_begin_block ();

		current_scope = ns.scope;

		visit_sorted (ns.get_namespaces ());
		visit_sorted (ns.get_classes ());
		visit_sorted (ns.get_interfaces ());
		visit_sorted (ns.get_structs ());
		visit_sorted (ns.get_enums ());
		visit_sorted (ns.get_error_domains ());
		visit_sorted (ns.get_delegates ());
		visit_sorted (ns.get_fields ());
		visit_sorted (ns.get_constants ());
		visit_sorted (ns.get_methods ());

		current_scope = current_scope.parent_scope;

		write_end_block ();
		write_newline ();
	}

	private string get_cheaders (Symbol sym) {
		string cheaders = "";
		if (type != CodeWriterType.FAST && !sym.external_package) {
			cheaders = sym.get_attribute_string ("CCode", "cheader_filename") ?? "";
			if (cheaders == "" && sym.parent_symbol != null && sym.parent_symbol != context.root) {
				cheaders = get_cheaders (sym.parent_symbol);
			}
			if (cheaders == "" && sym.source_reference != null && !sym.external_package) {
				cheaders = sym.source_reference.file.get_cinclude_filename ();
			}

			if (header_to_override != null) {
				cheaders = cheaders.replace (header_to_override, override_header).replace (",,", ",");
			}
		}
		return cheaders;
	}

	public override void visit_class (Class cl) {
		if (cl.external_package) {
			return;
		}

		if (!check_accessibility (cl)) {
			return;
		}

		write_attributes (cl);
		
		write_indent ();
		write_accessibility (cl);
		if (cl.is_abstract) {
			write_string ("abstract ");
		}
		write_string ("class ");
		write_identifier (cl.name);

		write_type_parameters (cl.get_type_parameters ());

		var base_types = cl.get_base_types ();
		if (base_types.size > 0) {
			write_string (" : ");
		
			bool first = true;
			foreach (DataType base_type in base_types) {
				if (!first) {
					write_string (", ");
				} else {
					first = false;
				}
				write_type (base_type);
			}
		}
		write_begin_block ();

		current_scope = cl.scope;

		visit_sorted (cl.get_classes ());
		visit_sorted (cl.get_structs ());
		visit_sorted (cl.get_enums ());
		visit_sorted (cl.get_delegates ());
		visit_sorted (cl.get_fields ());
		visit_sorted (cl.get_constants ());
		visit_sorted (cl.get_methods ());
		visit_sorted (cl.get_properties ());
		visit_sorted (cl.get_signals ());

		if (cl.constructor != null) {
			cl.constructor.accept (this);
		}

		current_scope = current_scope.parent_scope;

		write_end_block ();
		write_newline ();
	}

	void visit_sorted (List<Symbol> symbols) {
		if (type != CodeWriterType.EXTERNAL) {
			// order of virtual methods matters for fast vapis
			foreach (Symbol sym in symbols) {
				sym.accept (this);
			}
			return;
		}

		var sorted_symbols = new ArrayList<Symbol> ();
		foreach (Symbol sym in symbols) {
			int left = 0;
			int right = sorted_symbols.size - 1;
			if (left > right || sym.name < sorted_symbols[left].name) {
				sorted_symbols.insert (0, sym);
			} else if (sym.name > sorted_symbols[right].name) {
				sorted_symbols.add (sym);
			} else {
				while (right - left > 1) {
					int i = (right + left) / 2;
					if (sym.name > sorted_symbols[i].name) {
						left = i;
					} else {
						right = i;
					}
				}
				sorted_symbols.insert (left + 1, sym);
			}
		}
		foreach (Symbol sym in sorted_symbols) {
			sym.accept (this);
		}
	}

	public override void visit_struct (Struct st) {
		if (st.external_package) {
			return;
		}

		if (!check_accessibility (st)) {
			return;
		}

		write_attributes (st);

		write_indent ();
		write_accessibility (st);
		write_string ("struct ");
		write_identifier (st.name);

		write_type_parameters (st.get_type_parameters ());

		if (st.base_type != null) {
			write_string (" : ");
			write_type (st.base_type);
		}

		write_begin_block ();

		current_scope = st.scope;

		foreach (Field field in st.get_fields ()) {
			field.accept (this);
		}
		visit_sorted (st.get_constants ());
		visit_sorted (st.get_methods ());
		visit_sorted (st.get_properties ());

		current_scope = current_scope.parent_scope;

		write_end_block ();
		write_newline ();
	}

	public override void visit_interface (Interface iface) {
		if (iface.external_package) {
			return;
		}

		if (!check_accessibility (iface)) {
			return;
		}

		write_attributes (iface);

		write_indent ();
		write_accessibility (iface);
		write_string ("interface ");
		write_identifier (iface.name);

		write_type_parameters (iface.get_type_parameters ());

		var prerequisites = iface.get_prerequisites ();
		if (prerequisites.size > 0) {
			write_string (" : ");
		
			bool first = true;
			foreach (DataType prerequisite in prerequisites) {
				if (!first) {
					write_string (", ");
				} else {
					first = false;
				}
				write_type (prerequisite);
			}
		}
		write_begin_block ();

		current_scope = iface.scope;

		visit_sorted (iface.get_classes ());
		visit_sorted (iface.get_structs ());
		visit_sorted (iface.get_enums ());
		visit_sorted (iface.get_delegates ());
		visit_sorted (iface.get_fields ());
		visit_sorted (iface.get_constants ());
		visit_sorted (iface.get_methods ());
		visit_sorted (iface.get_properties ());
		visit_sorted (iface.get_signals ());

		current_scope = current_scope.parent_scope;

		write_end_block ();
		write_newline ();
	}

	public override void visit_enum (Enum en) {
		if (en.external_package) {
			return;
		}

		if (!check_accessibility (en)) {
			return;
		}

		write_attributes (en);

		write_indent ();
		write_accessibility (en);
		write_string ("enum ");
		write_identifier (en.name);
		write_begin_block ();

		bool first = true;
		foreach (EnumValue ev in en.get_values ()) {
			if (first) {
				first = false;
			} else {
				write_string (",");
				write_newline ();
			}

			write_attributes (ev);

			write_indent ();
			write_identifier (ev.name);

			if (type == CodeWriterType.FAST && ev.value != null) {
				write_string(" = ");
				ev.value.accept (this);
			}
		}

		if (!first) {
			if (en.get_methods ().size > 0 || en.get_constants ().size > 0) {
				write_string (";");
			}
			write_newline ();
		}

		current_scope = en.scope;
		foreach (Method m in en.get_methods ()) {
			m.accept (this);
		}
		foreach (Constant c in en.get_constants ()) {
			c.accept (this);
		}
		current_scope = current_scope.parent_scope;

		write_end_block ();
		write_newline ();
	}

	public override void visit_error_domain (ErrorDomain edomain) {
		if (edomain.external_package) {
			return;
		}

		if (!check_accessibility (edomain)) {
			return;
		}

		write_attributes (edomain);

		write_indent ();
		write_accessibility (edomain);
		write_string ("errordomain ");
		write_identifier (edomain.name);
		write_begin_block ();

		bool first = true;
		foreach (ErrorCode ecode in edomain.get_codes ()) {
			if (first) {
				first = false;
			} else {
				write_string (",");
				write_newline ();
			}

			write_attributes (ecode);

			write_indent ();
			write_identifier (ecode.name);
		}

		if (!first) {
			if (edomain.get_methods ().size > 0) {
				write_string (";");
			}
			write_newline ();
		}

		current_scope = edomain.scope;
		foreach (Method m in edomain.get_methods ()) {
			m.accept (this);
		}
		current_scope = current_scope.parent_scope;

		write_end_block ();
		write_newline ();
	}

	public override void visit_constant (Constant c) {
		if (c.external_package) {
			return;
		}

		if (!check_accessibility (c)) {
			return;
		}

		write_attributes (c);

		write_indent ();
		write_accessibility (c);
		write_string ("const ");

		write_type (c.type_reference);
			
		write_string (" ");
		write_identifier (c.name);
		if (type == CodeWriterType.FAST && c.value != null) {
			write_string(" = ");
			c.value.accept (this);
		}
		write_string (";");
		write_newline ();
	}

	public override void visit_field (Field f) {
		if (f.external_package) {
			return;
		}

		if (!check_accessibility (f)) {
			return;
		}

		write_attributes (f);

		write_indent ();
		write_accessibility (f);

		if (f.binding == MemberBinding.STATIC) {
			write_string ("static ");
		} else if (f.binding == MemberBinding.CLASS) {
			write_string ("class ");
		}

		if (f.variable_type.is_weak ()) {
			write_string ("weak ");
		}

		write_type (f.variable_type);
			
		write_string (" ");
		write_identifier (f.name);
		write_string (";");
		write_newline ();
	}
	
	private void write_error_domains (List<DataType> error_domains) {
		if (error_domains.size > 0) {
			write_string (" throws ");

			bool first = true;
			foreach (DataType type in error_domains) {
				if (!first) {
					write_string (", ");
				} else {
					first = false;
				}

				write_type (type);
			}
		}
	}

	private void write_params (List<Parameter> params) {
		write_string ("(");

		int i = 1;
		foreach (Parameter param in params) {
			if (i > 1) {
				write_string (", ");
			}
			
			if (param.ellipsis) {
				write_string ("...");
				continue;
			}
			
			write_attributes (param);

			if (param.params_array) {
				write_string ("params ");
			}

			if (param.direction == ParameterDirection.IN) {
				if (param.variable_type.value_owned) {
					write_string ("owned ");
				}
			} else {
				if (param.direction == ParameterDirection.REF) {
					write_string ("ref ");
				} else if (param.direction == ParameterDirection.OUT) {
					write_string ("out ");
				}
				if (param.variable_type.is_weak ()) {
					write_string ("unowned ");
				}
			}

			write_type (param.variable_type);

			write_string (" ");
			write_identifier (param.name);
			
			if (param.initializer != null) {
				write_string (" = ");
				param.initializer.accept (this);
			}

			i++;
		}

		write_string (")");
	}

	public override void visit_delegate (Delegate cb) {
		if (cb.external_package) {
			return;
		}

		if (!check_accessibility (cb)) {
			return;
		}

		write_attributes (cb);

		write_indent ();

		write_accessibility (cb);
		write_string ("delegate ");
		
		write_return_type (cb.return_type);
		
		write_string (" ");
		write_identifier (cb.name);

		write_type_parameters (cb.get_type_parameters ());

		write_string (" ");
		
		write_params (cb.get_parameters ());

		write_error_domains (cb.get_error_types ());

		write_string (";");

		write_newline ();
	}

	public override void visit_constructor (Constructor c) {
		if (type != CodeWriterType.DUMP) {
			return;
		}

		write_indent ();
		write_string ("construct");
		write_code_block (c.body);
		write_newline ();
	}

	public override void visit_method (Method m) {
		if (m.external_package) {
			return;
		}

		// don't write interface implementation unless it's an abstract or virtual method
		if (!check_accessibility (m) || (m.base_interface_method != null && !m.is_abstract && !m.is_virtual)) {
			if (type != CodeWriterType.DUMP) {
				return;
			}
		}

		write_attributes (m);

		write_indent ();
		write_accessibility (m);
		
		if (m is CreationMethod) {
			if (m.coroutine) {
				write_string ("async ");
			}

			var datatype = (TypeSymbol) m.parent_symbol;
			write_identifier (datatype.name);
			if (m.name != ".new") {
				write_string (".");
				write_identifier (m.name);
			}
			write_string (" ");
		} else {
			if (m.binding == MemberBinding.STATIC) {
				write_string ("static ");
			} else if (m.binding == MemberBinding.CLASS) {
				write_string ("class ");
			} else if (m.is_abstract) {
				write_string ("abstract ");
			} else if (m.is_virtual) {
				write_string ("virtual ");
			} else if (m.overrides) {
				write_string ("override ");
			}

			if (m.hides) {
				write_string ("new ");
			}

			if (m.coroutine) {
				write_string ("async ");
			}
		
			write_return_type (m.return_type);
			write_string (" ");

			write_identifier (m.name);

			write_type_parameters (m.get_type_parameters ());

			write_string (" ");
		}
		
		write_params (m.get_parameters ());

		write_error_domains (m.get_error_types ());

		write_code_block (m.body);

		write_newline ();
	}

	public override void visit_creation_method (CreationMethod m) {
		visit_method (m);
	}

	public override void visit_property (Property prop) {
		if (!check_accessibility (prop) || (prop.base_interface_property != null && !prop.is_abstract && !prop.is_virtual)) {
			return;
		}

		write_attributes (prop);

		write_indent ();
		write_accessibility (prop);

		if (prop.binding == MemberBinding.STATIC) {
			write_string ("static ");
		} else  if (prop.is_abstract) {
			write_string ("abstract ");
		} else if (prop.is_virtual) {
			write_string ("virtual ");
		} else if (prop.overrides) {
			write_string ("override ");
		}

		write_type (prop.property_type);

		write_string (" ");
		write_identifier (prop.name);
		write_string (" {");
		if (prop.get_accessor != null) {
			write_attributes (prop.get_accessor);

			write_property_accessor_accessibility (prop.get_accessor);

			if (prop.get_accessor.value_type.is_disposable ()) {
				write_string (" owned");
			}

			write_string (" get");
			write_code_block (prop.get_accessor.body);
		}
		if (prop.set_accessor != null) {
			write_attributes (prop.set_accessor);

			write_property_accessor_accessibility (prop.set_accessor);

			if (prop.set_accessor.value_type.value_owned) {
				write_string (" owned");
			}

			if (prop.set_accessor.writable) {
				write_string (" set");
			}
			if (prop.set_accessor.construction) {
				write_string (" construct");
			}
			write_code_block (prop.set_accessor.body);
		}
		write_string (" }");
		write_newline ();
	}

	public override void visit_signal (Signal sig) {
		if (!check_accessibility (sig)) {
			return;
		}
		
		write_attributes (sig);
		
		write_indent ();
		write_accessibility (sig);

		if (sig.is_virtual) {
			write_string ("virtual ");
		}

		write_string ("signal ");
		
		write_return_type (sig.return_type);
		
		write_string (" ");
		write_identifier (sig.name);
		
		write_string (" ");
		
		write_params (sig.get_parameters ());

		write_string (";");

		write_newline ();
	}

	public override void visit_block (Block b) {
		write_begin_block ();

		foreach (Statement stmt in b.get_statements ()) {
			stmt.accept (this);
		}

		write_end_block ();
	}

	public override void visit_empty_statement (EmptyStatement stmt) {
	}

	public override void visit_declaration_statement (DeclarationStatement stmt) {
		write_indent ();
		stmt.declaration.accept (this);
		write_string (";");
		write_newline ();
	}

	public override void visit_local_variable (LocalVariable local) {
		write_type (local.variable_type);
		write_string (" ");
		write_identifier (local.name);
		if (local.initializer != null) {
			write_string (" = ");
			local.initializer.accept (this);
		}
	}

	public override void visit_initializer_list (InitializerList list) {
		write_string ("{");

		bool first = true;
		foreach (Expression initializer in list.get_initializers ()) {
			if (!first) {
				write_string (", ");
			} else {
				write_string (" ");
			}
			first = false;
			initializer.accept (this);
		}
		write_string (" }");
	}

	public override void visit_expression_statement (ExpressionStatement stmt) {
		write_indent ();
		stmt.expression.accept (this);
		write_string (";");
		write_newline ();
	}

	public override void visit_if_statement (IfStatement stmt) {
		write_indent ();
		write_string ("if (");
		stmt.condition.accept (this);
		write_string (")");
		stmt.true_statement.accept (this);
		if (stmt.false_statement != null) {
			write_string (" else");
			stmt.false_statement.accept (this);
		}
		write_newline ();
	}

	public override void visit_switch_statement (SwitchStatement stmt) {
		write_indent ();
		write_string ("switch (");
		stmt.expression.accept (this);
		write_string (") {");
		write_newline ();

		foreach (SwitchSection section in stmt.get_sections ()) {
			section.accept (this);
		}

		write_indent ();
		write_string ("}");
		write_newline ();
	}

	public override void visit_switch_section (SwitchSection section) {
		foreach (SwitchLabel label in section.get_labels ()) {
			label.accept (this);
		}

		visit_block (section);
	}

	public override void visit_switch_label (SwitchLabel label) {
		if (label.expression != null) {
			write_indent ();
			write_string ("case ");
			label.expression.accept (this);
			write_string (":");
			write_newline ();
		} else {
			write_indent ();
			write_string ("default:");
			write_newline ();
		}
	}

	public override void visit_loop (Loop stmt) {
		write_indent ();
		write_string ("loop");
		stmt.body.accept (this);
		write_newline ();
	}

	public override void visit_while_statement (WhileStatement stmt) {
		write_indent ();
		write_string ("while (");
		stmt.condition.accept (this);
		write_string (")");
		stmt.body.accept (this);
		write_newline ();
	}

	public override void visit_do_statement (DoStatement stmt) {
		write_indent ();
		write_string ("do");
		stmt.body.accept (this);
		write_string ("while (");
		stmt.condition.accept (this);
		write_string (");");
		write_newline ();
	}

	public override void visit_for_statement (ForStatement stmt) {
		write_indent ();
		write_string ("for (");

		bool first = true;
		foreach (Expression initializer in stmt.get_initializer ()) {
			if (!first) {
				write_string (", ");
			}
			first = false;
			initializer.accept (this);
		}
		write_string ("; ");

		stmt.condition.accept (this);
		write_string ("; ");

		first = true;
		foreach (Expression iterator in stmt.get_iterator ()) {
			if (!first) {
				write_string (", ");
			}
			first = false;
			iterator.accept (this);
		}

		write_string (")");
		stmt.body.accept (this);
		write_newline ();
	}

	public override void visit_foreach_statement (ForeachStatement stmt) {
	}

	public override void visit_break_statement (BreakStatement stmt) {
		write_indent ();
		write_string ("break;");
		write_newline ();
	}

	public override void visit_continue_statement (ContinueStatement stmt) {
		write_indent ();
		write_string ("continue;");
		write_newline ();
	}

	public override void visit_return_statement (ReturnStatement stmt) {
		write_indent ();
		write_string ("return");
		if (stmt.return_expression != null) {
			write_string (" ");
			stmt.return_expression.accept (this);
		}
		write_string (";");
		write_newline ();
	}

	public override void visit_yield_statement (YieldStatement y) {
		write_indent ();
		write_string ("yield");
		if (y.yield_expression != null) {
			write_string (" ");
			y.yield_expression.accept (this);
		}
		write_string (";");
		write_newline ();
	}

	public override void visit_throw_statement (ThrowStatement stmt) {
		write_indent ();
		write_string ("throw");
		if (stmt.error_expression != null) {
			write_string (" ");
			stmt.error_expression.accept (this);
		}
		write_string (";");
		write_newline ();
	}

	public override void visit_try_statement (TryStatement stmt) {
		write_indent ();
		write_string ("try");
		stmt.body.accept (this);
		foreach (var clause in stmt.get_catch_clauses ()) {
			clause.accept (this);
		}
		if (stmt.finally_body != null) {
			write_string (" finally");
			stmt.finally_body.accept (this);
		}
		write_newline ();
	}

	public override void visit_catch_clause (CatchClause clause) {
		var type_name = clause.error_type == null ? "GLib.Error" : clause.error_type.to_string ();
		var var_name = clause.variable_name == null ? "_" : clause.variable_name;
		write_string (" catch (%s %s)".printf (type_name, var_name));
		clause.body.accept (this);
	}

	public override void visit_lock_statement (LockStatement stmt) {
		write_indent ();
		write_string ("lock (");
		stmt.resource.accept (this);
		write_string (")");
		if (stmt.body == null) {
			write_string (";");
		} else {
			stmt.body.accept (this);
		}
		write_newline ();
	}

	public override void visit_delete_statement (DeleteStatement stmt) {
		write_indent ();
		write_string ("delete ");
		stmt.expression.accept (this);
		write_string (";");
		write_newline ();
	}

	public override void visit_array_creation_expression (ArrayCreationExpression expr) {
		write_string ("new ");
		write_type (expr.element_type);
		write_string ("[");

		bool first = true;
		foreach (Expression size in expr.get_sizes ()) {
			if (!first) {
				write_string (", ");
			}
			first = false;

			size.accept (this);
		}

		write_string ("]");

		if (expr.initializer_list != null) {
			write_string (" ");
			expr.initializer_list.accept (this);
		}
	}

	public override void visit_boolean_literal (BooleanLiteral lit) {
		write_string (lit.value.to_string ());
	}

	public override void visit_character_literal (CharacterLiteral lit) {
		write_string (lit.value);
	}

	public override void visit_integer_literal (IntegerLiteral lit) {
		write_string (lit.value);
	}

	public override void visit_real_literal (RealLiteral lit) {
		write_string (lit.value);
	}

	public override void visit_string_literal (StringLiteral lit) {
		write_string (lit.value);
	}

	public override void visit_null_literal (NullLiteral lit) {
		write_string ("null");
	}

	public override void visit_member_access (MemberAccess expr) {
		if (expr.inner != null) {
			expr.inner.accept (this);
			write_string (".");
		}
		write_identifier (expr.member_name);
	}

	public override void visit_method_call (MethodCall expr) {
		expr.call.accept (this);
		write_string (" (");

		bool first = true;
		foreach (Expression arg in expr.get_argument_list ()) {
			if (!first) {
				write_string (", ");
			}
			first = false;

			arg.accept (this);
		}

		write_string (")");
	}
	
	public override void visit_element_access (ElementAccess expr) {
		expr.container.accept (this);
		write_string ("[");

		bool first = true;
		foreach (Expression index in expr.get_indices ()) {
			if (!first) {
				write_string (", ");
			}
			first = false;

			index.accept (this);
		}

		write_string ("]");
	}

	public override void visit_slice_expression (SliceExpression expr) {
		expr.container.accept (this);
		write_string ("[");
		expr.start.accept (this);
		write_string (":");
		expr.stop.accept (this);
		write_string ("]");
	}

	public override void visit_base_access (BaseAccess expr) {
		write_string ("base");
	}

	public override void visit_postfix_expression (PostfixExpression expr) {
		expr.inner.accept (this);
		if (expr.increment) {
			write_string ("++");
		} else {
			write_string ("--");
		}
	}

	public override void visit_object_creation_expression (ObjectCreationExpression expr) {
		if (!expr.struct_creation) {
			write_string ("new ");
		}

		write_type (expr.type_reference);

		if (expr.symbol_reference.name != ".new") {
			write_string (".");
			write_string (expr.symbol_reference.name);
		}

		write_string (" (");

		bool first = true;
		foreach (Expression arg in expr.get_argument_list ()) {
			if (!first) {
				write_string (", ");
			}
			first = false;

			arg.accept (this);
		}

		write_string (")");
	}

	public override void visit_sizeof_expression (SizeofExpression expr) {
		write_string ("sizeof (");
		write_type (expr.type_reference);
		write_string (")");
	}

	public override void visit_typeof_expression (TypeofExpression expr) {
		write_string ("typeof (");
		write_type (expr.type_reference);
		write_string (")");
	}

	public override void visit_unary_expression (UnaryExpression expr) {
		switch (expr.operator) {
		case UnaryOperator.PLUS:
			write_string ("+");
			break;
		case UnaryOperator.MINUS:
			write_string ("-");
			break;
		case UnaryOperator.LOGICAL_NEGATION:
			write_string ("!");
			break;
		case UnaryOperator.BITWISE_COMPLEMENT:
			write_string ("~");
			break;
		case UnaryOperator.INCREMENT:
			write_string ("++");
			break;
		case UnaryOperator.DECREMENT:
			write_string ("--");
			break;
		case UnaryOperator.REF:
			write_string ("ref ");
			break;
		case UnaryOperator.OUT:
			write_string ("out ");
			break;
		default:
			assert_not_reached ();
		}
		expr.inner.accept (this);
	}

	public override void visit_cast_expression (CastExpression expr) {
		if (expr.is_non_null_cast) {
			write_string ("(!) ");
			expr.inner.accept (this);
			return;
		}

		if (!expr.is_silent_cast) {
			write_string ("(");
			write_type (expr.type_reference);
			write_string (") ");
		}

		expr.inner.accept (this);

		if (expr.is_silent_cast) {
			write_string (" as ");
			write_type (expr.type_reference);
		}
	}

	public override void visit_pointer_indirection (PointerIndirection expr) {
		write_string ("*");
		expr.inner.accept (this);
	}

	public override void visit_addressof_expression (AddressofExpression expr) {
		write_string ("&");
		expr.inner.accept (this);
	}

	public override void visit_reference_transfer_expression (ReferenceTransferExpression expr) {
		write_string ("(owned) ");
		expr.inner.accept (this);
	}

	public override void visit_binary_expression (BinaryExpression expr) {
		expr.left.accept (this);

		switch (expr.operator) {
		case BinaryOperator.PLUS:
			write_string (" + ");
			break;
		case BinaryOperator.MINUS:
			write_string (" - ");
			break;
		case BinaryOperator.MUL:
			write_string (" * ");
			break;
		case BinaryOperator.DIV:
			write_string (" / ");
			break;
		case BinaryOperator.MOD:
			write_string (" % ");
			break;
		case BinaryOperator.SHIFT_LEFT:
			write_string (" << ");
			break;
		case BinaryOperator.SHIFT_RIGHT:
			write_string (" >> ");
			break;
		case BinaryOperator.LESS_THAN:
			write_string (" < ");
			break;
		case BinaryOperator.GREATER_THAN:
			write_string (" > ");
			break;
		case BinaryOperator.LESS_THAN_OR_EQUAL:
			write_string (" <= ");
			break;
		case BinaryOperator.GREATER_THAN_OR_EQUAL:
			write_string (" >= ");
			break;
		case BinaryOperator.EQUALITY:
			write_string (" == ");
			break;
		case BinaryOperator.INEQUALITY:
			write_string (" != ");
			break;
		case BinaryOperator.BITWISE_AND:
			write_string (" & ");
			break;
		case BinaryOperator.BITWISE_OR:
			write_string (" | ");
			break;
		case BinaryOperator.BITWISE_XOR:
			write_string (" ^ ");
			break;
		case BinaryOperator.AND:
			write_string (" && ");
			break;
		case BinaryOperator.OR:
			write_string (" || ");
			break;
		case BinaryOperator.IN:
			write_string (" in ");
			break;
		case BinaryOperator.COALESCE:
			write_string (" ?? ");
			break;
		default:
			assert_not_reached ();
		}

		expr.right.accept (this);
	}

	public override void visit_type_check (TypeCheck expr) {
		expr.expression.accept (this);
		write_string (" is ");
		write_type (expr.type_reference);
	}

	public override void visit_conditional_expression (ConditionalExpression expr) {
		expr.condition.accept (this);
		write_string ("?");
		expr.true_expression.accept (this);
		write_string (":");
		expr.false_expression.accept (this);
	}

	public override void visit_lambda_expression (LambdaExpression expr) {
		write_string ("(");
		var params = expr.get_parameters ();
		int i = 1;
		foreach (var param in params) {
			if (i > 1) {
				write_string (", ");
			}

			if (param.direction == ParameterDirection.REF) {
				write_string ("ref ");
			} else if (param.direction == ParameterDirection.OUT) {
				write_string ("out ");
			}

			write_identifier (param.name);

			i++;
		}
		write_string (") =>");
		if (expr.statement_body != null) {
			expr.statement_body.accept (this);
		} else if (expr.expression_body != null) {
			expr.expression_body.accept (this);
		}
	}

	public override void visit_assignment (Assignment a) {
		a.left.accept (this);
		write_string (" = ");
		a.right.accept (this);
	}

	private void write_indent () {
		int i;
		
		if (!bol) {
			stream.putc ('\n');
		}
		
		for (i = 0; i < indent; i++) {
			stream.putc ('\t');
		}
		
		bol = false;
	}
	
	private void write_identifier (string s) {
		char* id = (char*)s;
		int id_length = (int)s.length;
		if (Vala.Scanner.get_identifier_or_keyword (id, id_length) != Vala.TokenType.IDENTIFIER ||
		    s.get_char ().isdigit ()) {
			stream.putc ('@'); 
		}
		write_string (s);
	}

	private void write_return_type (DataType type) {
		if (type.is_weak ()) {
			write_string ("unowned ");
		}

		write_type (type);
	}

	private void write_type (DataType type) {
		write_string (type.to_qualified_string (current_scope));
	}

	private void write_string (string s) {
		stream.printf ("%s", s);
		bol = false;
	}
	
	private void write_newline () {
		stream.putc ('\n');
		bol = true;
	}
	
	void write_code_block (Block? block) {
		if (block == null || type != CodeWriterType.DUMP) {
			write_string (";");
			return;
		}

		block.accept (this);
	}

	private void write_begin_block () {
		if (!bol) {
			stream.putc (' ');
		} else {
			write_indent ();
		}
		stream.putc ('{');
		write_newline ();
		indent++;
	}
	
	private void write_end_block () {
		indent--;
		write_indent ();
		stream.printf ("}");
	}

	private bool check_accessibility (Symbol sym) {
		switch (type) {
		case CodeWriterType.EXTERNAL:
			return sym.access == SymbolAccessibility.PUBLIC ||
			       sym.access == SymbolAccessibility.PROTECTED;

		case CodeWriterType.INTERNAL:
		case CodeWriterType.FAST:
			return sym.access == SymbolAccessibility.INTERNAL ||
			       sym.access == SymbolAccessibility.PUBLIC ||
			       sym.access == SymbolAccessibility.PROTECTED;

		case CodeWriterType.DUMP:
			return true;

		default:
			assert_not_reached ();
		}
	}

	private void write_attributes (CodeNode node) {
		var sym = node as Symbol;

		var need_cheaders = type != CodeWriterType.FAST && sym != null && !(sym is Namespace) && sym.parent_symbol is Namespace;

		var attributes = new GLib.Sequence<Attribute> ();
		foreach (var attr in node.attributes) {
			attributes.insert_sorted (attr, (a, b) => strcmp (a.name, b.name));
		}
		if (need_cheaders && node.get_attribute ("CCode") == null) {
			attributes.insert_sorted (new Attribute ("CCode"), (a, b) => strcmp (a.name, b.name));
		}

		var iter = attributes.get_begin_iter ();
		while (!iter.is_end ()) {
			unowned Attribute attr = iter.get ();
			iter = iter.next ();

			var keys = new GLib.Sequence<string> ();
			foreach (var key in attr.args.get_keys ()) {
				if (key == "cheader_filename" && sym is Namespace) {
					continue;
				}
				keys.insert_sorted (key, (CompareDataFunc) strcmp);
			}
			if (need_cheaders && attr.name == "CCode" && !attr.has_argument ("cheader_filename")) {
				keys.insert_sorted ("cheader_filename", (CompareDataFunc) strcmp);
			}

			if (attr.name == "CCode" && keys.get_length () == 0) {
				// only cheader_filename on namespace
				continue;
			}

			if (!(node is Parameter)) {
				write_indent ();
			}

			stream.printf ("[%s", attr.name);
			if (keys.get_length () > 0) {
				stream.printf (" (");

				string separator = "";
				var arg_iter = keys.get_begin_iter ();
				while (!arg_iter.is_end ()) {
					unowned string arg_name = arg_iter.get ();
					arg_iter = arg_iter.next ();
					if (arg_name == "cheader_filename") {
						stream.printf ("%scheader_filename = \"%s\"", separator, get_cheaders (sym));
					} else {
						stream.printf ("%s%s = %s", separator, arg_name, attr.args.get (arg_name));
					}
					separator = ", ";
				}

				stream.printf (")");
			}
			stream.printf ("]");
			if (node is Parameter) {
				write_string (" ");
			} else {
				write_newline ();
			}
		}
	}

	private void write_accessibility (Symbol sym) {
		if (sym.access == SymbolAccessibility.PUBLIC) {
			write_string ("public ");
		} else if (sym.access == SymbolAccessibility.PROTECTED) {
			write_string ("protected ");
		} else if (sym.access == SymbolAccessibility.INTERNAL) {
			write_string ("internal ");
		} else if (sym.access == SymbolAccessibility.PRIVATE) {
			write_string ("private ");
		}

		if (type != CodeWriterType.EXTERNAL && sym.external && !sym.external_package) {
			write_string ("extern ");
		}
	}

	void write_property_accessor_accessibility (Symbol sym) {
		if (sym.access == SymbolAccessibility.PROTECTED) {
			write_string (" protected");
		} else if (sym.access == SymbolAccessibility.INTERNAL) {
			write_string (" internal");
		} else if (sym.access == SymbolAccessibility.PRIVATE) {
			write_string (" private");
		}
	}

	void write_type_parameters (List<TypeParameter> type_params) {
		if (type_params.size > 0) {
			write_string ("<");
			bool first = true;
			foreach (TypeParameter type_param in type_params) {
				if (first) {
					first = false;
				} else {
					write_string (",");
				}
				write_identifier (type_param.name);
			}
			write_string (">");
		}
	}
}

public enum Vala.CodeWriterType {
	EXTERNAL,
	INTERNAL,
	FAST,
	DUMP
}
